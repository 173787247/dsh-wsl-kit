#!/usr/bin/env bash
# Quick health for Agent-in-WSL + browser-on-Windows: ports, dsh env, optional proxy TCP.
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0

code() {
  curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 "$1" || echo fail
}

# dsh ≥0.1.2: bare / is 401 until ?token= from the launch URL (303 after auth).
# 200/3xx/401 = HTTP stack up. Connection fail / 502 = down.
# shellcheck source=dsh-web-alive.inc.sh
source "${SCRIPT_DIR}/dsh-web-alive.inc.sh"

echo "=== ports ==="
c3080="$(code http://127.0.0.1:3080/)"
c3081="$(code http://127.0.0.1:3081/)"
echo "3080=${c3080} 3081=${c3081}"
if ! dsh_http_up "$c3080" || ! dsh_http_up "$c3081"; then
  echo "FAIL: open the URL from bash ${SCRIPT_DIR}/restart-dsh-web.sh (3081 + token on dsh ≥0.1.2)"
  fail=1
else
  ui="$(dsh_write_ui_url /tmp/dsh-web.log)"
  echo "ui=${ui}"
  echo "OPEN_THIS_URL=${ui}"
  if [[ -f /tmp/dsh-ui-url ]]; then
    echo "ui_file=/tmp/dsh-ui-url"
  fi
  if [[ "$c3080" == "401" || "$c3081" == "401" ]]; then
    echo "NOTE: 401 is expected without ?token= (dsh 0.1.2+). Use OPEN_THIS_URL above, not bare :3081."
  fi
  if [[ "$ui" == *token=* ]]; then
    if command -v clip.exe >/dev/null 2>&1; then
      printf '%s' "$ui" | clip.exe && echo "clipboard=OPEN_THIS_URL (Windows clip.exe)"
    elif command -v xclip >/dev/null 2>&1; then
      printf '%s' "$ui" | xclip -selection clipboard && echo "clipboard=OPEN_THIS_URL (xclip)"
    else
      echo "clipboard=skip (no clip.exe/xclip) — copy OPEN_THIS_URL manually"
    fi
  else
    echo "WARN: ui URL has no token — bash ${SCRIPT_DIR}/restart-dsh-web.sh"
    fail=1
  fi
fi

echo "=== dsh web process ==="
PID="$(pgrep -n -f 'node.*/dsh web' || true)"
if [[ -z "${PID}" ]]; then
  echo "FAIL: dsh web not running — bash ${SCRIPT_DIR}/restart-dsh-web.sh"
  fail=1
else
  echo "pid=${PID}"
  # Print presence only (no secret values)
  ENV_FILE="/proc/${PID}/environ"
  if [[ -r "$ENV_FILE" ]]; then
    tr '\0' '\n' < "$ENV_FILE" | awk -F= '
      $1=="NODE_USE_ENV_PROXY"{print "NODE_USE_ENV_PROXY="$2}
      $1=="HTTP_PROXY"||$1=="http_proxy"{print "HTTP_PROXY=set"}
      $1=="HTTPS_PROXY"||$1=="https_proxy"{print "HTTPS_PROXY=set"}
    ' | sort -u
    NUEP="$(tr '\0' '\n' < "$ENV_FILE" | awk -F= '$1=="NODE_USE_ENV_PROXY"{print $2; exit}')"
    if [[ "${NUEP}" != "1" ]]; then
      echo "FAIL: dsh web missing NODE_USE_ENV_PROXY=1 — bash ${SCRIPT_DIR}/restart-dsh-web.sh"
      fail=1
    fi
    PROXY_URL="$(tr '\0' '\n' < "$ENV_FILE" | awk -F= '$1=="HTTP_PROXY"||$1=="HTTPS_PROXY"||$1=="http_proxy"||$1=="https_proxy"{print $2; exit}')"
    if [[ -n "${PROXY_URL}" ]]; then
      hostport="$(python3 - <<PY
from urllib.parse import urlparse
u=urlparse("${PROXY_URL}")
print(f"{u.hostname or ''}:{u.port or 0}")
PY
)"
      host="${hostport%%:*}"
      port="${hostport##*:}"
      if [[ -n "$host" && "$port" != "0" ]]; then
        if timeout 1 bash -c "echo >/dev/tcp/${host}/${port}" 2>/dev/null; then
          echo "proxy_tcp=${host}:${port} OPEN"
        else
          echo "WARN: proxy_tcp=${host}:${port} closed"
        fi
      fi
    fi
  else
    echo "WARN: cannot read ${ENV_FILE}"
  fi
fi

if [[ "$fail" -ne 0 ]]; then
  echo "RESULT: unhealthy — bash ${SCRIPT_DIR}/restart-dsh-web.sh"
  exit 1
fi
echo "RESULT: healthy"
exit 0
