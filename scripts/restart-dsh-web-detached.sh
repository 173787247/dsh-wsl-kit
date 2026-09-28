#!/usr/bin/env bash
# Restart dsh web from a process that dsh web does not own, then open the browser.
#
# Why this exists, separately from restart-dsh-web.sh:
#
#   An agent running inside dsh web has a shell whose parent IS the dsh web
#   process. Verified with ps:
#
#     bash(97786) <- dsh web(97530) <- Relay(97518) <- systemd(1)
#
#   restart-dsh-web.sh begins by killing that process. Run it from inside a
#   session and the session dies before the script reaches its second line, so
#   the restart does not happen -- and it looks like the script failed when in
#   fact it never ran. setsid does not help: it changes the process group, not
#   the parent, so the caller is still a child of the process being killed.
#
# The whole job therefore goes into a systemd transient unit, not just the
# restart:
#
#   this script (caller)  --systemd-run-->  unit: restart + wait + open browser
#
# An earlier version ran only the restart under systemd and then waited in the
# caller to open the browser. That wait was still a child of dsh web, so it died
# with the process it was waiting for and the browser never opened -- the same
# failure this script exists to avoid, one level down.
#
#   bash scripts/restart-dsh-web-detached.sh          # restart, then open the UI
#   bash scripts/restart-dsh-web-detached.sh --dry    # show what would run
#   bash scripts/restart-dsh-web-detached.sh --inside # the unit's own entry point
#
#   DSH_NO_OPEN=1    do not open a browser (still writes the URL)
#   DSH_BROWSER=...  use this executable instead of Chrome
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── inside: this runs as the systemd unit, where dsh web is not an ancestor ──
if [[ "${1:-}" == "--inside" ]]; then
  # shellcheck source=dsh-web-alive.inc.sh
  source "${SCRIPT_DIR}/dsh-web-alive.inc.sh"

  echo "== restarting (port ${DSH_WEB_PORT:-3080}, log ${DSH_WEB_LOG:-/tmp/dsh-web.log})"
  bash "${SCRIPT_DIR}/restart-dsh-web.sh"

  if [[ -n "${DSH_NO_OPEN:-}" ]]; then
    echo "== DSH_NO_OPEN set; not opening a browser"
    # Read the log this instance actually writes. This line used to name
    # /tmp/dsh-web.log outright, so a rehearsal on another port read the live
    # instance's log, found no token, and overwrote its own URL file with the
    # bare 401 URL -- the same symptom as the original restart failure, arrived
    # at by a different route.
    ui="$(dsh_write_ui_url "$(dsh_web_log)")"
    echo "== wrote ${ui} to $(dsh_ui_url_file)"
    dsh_ui_url_usable "$ui" || exit 1
    exit 0
  fi

  # Wait for the new dsh rather than sleeping a fixed interval: the token appears
  # in the log only once the process is up, and a fixed sleep either races it or
  # wastes the difference.
  echo "== waiting for :${DSH_WEB_PORT:-3080} and a token"
  for _ in $(seq 1 24); do
    sleep 2
    code="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 "http://127.0.0.1:${DSH_WEB_PORT:-3080}/" 2>/dev/null || true)"
    dsh_http_up "${code:-}" || continue
    url="$(dsh_write_ui_url "$(dsh_web_log)")"
    if dsh_ui_url_usable "$url"; then
      echo "== opening ${url}"
      dsh_open_browser "$url" || true
      echo "== done; the URL is on the clipboard and in $(dsh_ui_url_file)"
      exit 0
    fi
    echo "   dsh answered (${code}) but the log has no token yet"
  done

  echo "gave up waiting for a token URL after 48s." >&2
  echo "check: tail -20 $(dsh_web_log)" >&2
  exit 1
fi

# ── caller: hand the whole job to systemd and return ─────────────────────────
if ! command -v systemd-run >/dev/null 2>&1; then
  cat >&2 <<'EOF'
systemd-run is not available, so there is no way to detach from dsh web here.

Run the restart from a shell that dsh web does not own instead -- a separate
terminal, a Windows shortcut, or the tray launcher. Anything started inside the
session shares its fate.
EOF
  exit 1
fi

if ! systemctl --user is-system-running >/dev/null 2>&1; then
  echo "the systemd user instance is not running; cannot detach." >&2
  exit 1
fi

# --collect so a failed unit does not block the next attempt with a name clash.
# KillMode=process: only the unit's main bash dies when the oneshot finishes.
# Default control-group would SIGKILL the setsid/nohup dsh web + relay that
# restart-dsh-web.sh left running in the same cgroup — which is exactly how
# dsh looked "up for 30s then gone" after a detached restart.
#
# The unit name carries a timestamp, and that is not cosmetic.
#
# KillMode=process keeps dsh web alive past the end of the unit, which is the
# whole point -- but it also means the process stays in the unit's cgroup.
# systemd will not garbage-collect a unit whose cgroup still has members, so
# --collect does nothing, and the unit stays loaded as inactive/dead. The next
# systemd-run with the same name then fails:
#
#   Failed to start transient service unit: Unit dsh-web-restart.service was
#   already loaded or has a fragment file.
#
# Neither `systemctl stop` nor `reset-failed` clears it: the unit is not failed,
# and stopping it does not unload it. So the first restart succeeds and every
# one after it fails on stderr while the script still exits 0.
#
# A fresh name each time removes the collision entirely. The name is printed, so
# the journal is still findable: journalctl --user -u <name>.
UNIT="${DSH_RESTART_UNIT:-dsh-web-restart}-$(date +%H%M%S)"

# Old ones accumulate for the same reason they cannot be collected. Worth
# clearing so `list-units` stays readable; failure here is not fatal.
systemctl --user reset-failed 'dsh-web-restart*' 2>/dev/null || true

ENVS=()
for v in DSH_WEB_PORT DSH_RELAY_PORT DSH_WEB_LOG DSH_UI_URL_FILE DSH_NO_OPEN DSH_BROWSER; do
  if [[ -n "${!v:-}" ]]; then ENVS+=(--setenv="${v}=${!v}"); fi
done

CMD=(systemd-run --user --collect "--unit=${UNIT}"
     --property=KillMode=process
     "${ENVS[@]}"
     --description="Restart dsh web and open the UI"
     bash "${SCRIPT_DIR}/restart-dsh-web-detached.sh" --inside)

if [[ "${1:-}" == "--dry" ]]; then
  echo "would run:"
  printf '  %q' "${CMD[@]}"
  echo
  echo
  echo "the unit runs the whole job -- restart, wait for a token, open the browser --"
  echo "because only a process outside dsh web survives the restart."
  echo
  echo "  DSH_NO_OPEN=1 skips opening a browser"
  echo "  DSH_BROWSER=<exe> overrides Chrome"
  echo
  echo "the restart itself is the same script as the foreground one:"
  sed -n '1,6p' "${SCRIPT_DIR}/restart-dsh-web.sh"
  exit 0
fi

echo "handing the whole restart to systemd (unit ${UNIT})"
echo "this session will die. that is expected and does not stop anything."
"${CMD[@]}"
echo
echo "when it is done a Chrome tab opens at the new token URL, and the same URL is"
echo "on the Windows clipboard. bare http://127.0.0.1:3081/ is a 401 by design."
echo
echo "if no tab appears within a minute:"
echo "  powershell.exe -NoProfile -Command Get-Clipboard      # paste that into Chrome"
echo "  journalctl --user -u ${UNIT} -n 40 --no-pager"
echo "  cat /tmp/dsh-ui-url"
