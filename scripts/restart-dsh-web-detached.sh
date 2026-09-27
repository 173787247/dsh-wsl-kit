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
UNIT="${DSH_RESTART_UNIT:-dsh-web-restart}"

# ── inside: this runs as the systemd unit, where dsh web is not an ancestor ──
if [[ "${1:-}" == "--inside" ]]; then
  # shellcheck source=dsh-web-alive.inc.sh
  source "${SCRIPT_DIR}/dsh-web-alive.inc.sh"

  echo "== restarting"
  bash "${SCRIPT_DIR}/restart-dsh-web.sh"

  if [[ -n "${DSH_NO_OPEN:-}" ]]; then
    echo "== DSH_NO_OPEN set; not opening a browser"
    dsh_write_ui_url /tmp/dsh-web.log || true
    exit 0
  fi

  # Wait for the new dsh rather than sleeping a fixed interval: the token appears
  # in the log only once the process is up, and a fixed sleep either races it or
  # wastes the difference.
  echo "== waiting for :3080 and a token"
  for _ in $(seq 1 24); do
    sleep 2
    code="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://127.0.0.1:3080/ 2>/dev/null || true)"
    dsh_http_up "${code:-}" || continue
    url="$(dsh_write_ui_url /tmp/dsh-web.log)"
    if dsh_ui_url_usable "$url"; then
      echo "== opening ${url}"
      dsh_open_browser "$url" || true
      echo "== done; the URL is on the clipboard and in /tmp/dsh-ui-url"
      exit 0
    fi
    echo "   dsh answered (${code}) but the log has no token yet"
  done

  echo "gave up waiting for a token URL after 48s." >&2
  echo "check: tail -20 /tmp/dsh-web.log" >&2
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
CMD=(systemd-run --user --collect "--unit=${UNIT}"
     --property=KillMode=process
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
