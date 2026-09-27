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
# What this does instead: hands the real work to the systemd user manager via
# systemd-run, whose transient unit is a child of systemd, not of dsh web.
#
#   bash scripts/restart-dsh-web-detached.sh          # restart, then open the UI
#   bash scripts/restart-dsh-web-detached.sh --dry    # show what would run
#   DSH_NO_OPEN=1 bash scripts/restart-dsh-web-detached.sh
#
# Opening the browser is the point. Bare http://127.0.0.1:3081/ is a 401 by
# design; the working URL carries a per-process token. Only Windows can open the
# Windows browser, so the opener runs on the Windows side via explorer.exe.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT="${DSH_RESTART_UNIT:-dsh-web-restart}"
OPEN="${DSH_NO_OPEN:+no}"; OPEN="${OPEN:-yes}"

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
CMD=(systemd-run --user --collect "--unit=${UNIT}" --description="Restart dsh web" bash "${SCRIPT_DIR}/restart-dsh-web.sh")

if [[ "${1:-}" == "--dry" ]]; then
  echo "would run:"
  printf '  %q' "${CMD[@]}"
  echo
  echo
  if [[ "$OPEN" == "yes" ]]; then
    echo "then, on this side, wait for :3080 and open the token URL in Chrome"
    echo "  (DSH_NO_OPEN=1 skips that step)"
  else
    echo "DSH_NO_OPEN is set: the browser will not be opened"
  fi
  echo
  echo "the restart itself is the same script as the foreground one:"
  sed -n '1,6p' "${SCRIPT_DIR}/restart-dsh-web.sh"
  exit 0
fi

echo "handing the restart to systemd (unit ${UNIT})"
echo "the calling session may die; that is expected and does not stop the restart"
"${CMD[@]}"

# Opening the browser has to happen from this side, because this is the process
# that survives. It waits for the new dsh to answer rather than sleeping a fixed
# interval: the token appears in the log only once the process is up, and a fixed
# sleep either races it or wastes the difference.
if [[ "${OPEN}" == "yes" ]]; then
  # shellcheck source=dsh-web-alive.inc.sh
  source "${SCRIPT_DIR}/dsh-web-alive.inc.sh"

  for _ in $(seq 1 24); do
    sleep 2
    code="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://127.0.0.1:3080/ 2>/dev/null || true)"
    dsh_http_up "${code:-}" || continue
    url="$(dsh_write_ui_url /tmp/dsh-web.log)"
    if dsh_ui_url_usable "$url"; then
      echo "opening ${url}"
      dsh_open_browser "$url"
      echo "if no tab appeared, open this yourself: ${url}"
      exit 0
    fi
    echo "dsh answered but the log has no token yet; still waiting"
  done

  echo "gave up waiting for a token URL after 48s." >&2
  echo "check: tail -20 /tmp/dsh-web.log" >&2
  echo "then :  bash ${SCRIPT_DIR}/restart-dsh-web.sh" >&2
  exit 1
fi

echo
echo "the URL is in /tmp/dsh-ui-url and in the last 'dsh web:' line of /tmp/dsh-web.log."
echo "a bare :3081 is a 401 by design."
