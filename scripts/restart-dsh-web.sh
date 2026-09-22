#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"
# Loopback only. Inheriting Clash RFC1918 NO_PROXY globs (10.*, 172.16.*, …)
# makes Node fetch bypass the proxy and TRANSPORT-timeout api.deepseek.com.
export NO_PROXY="127.0.0.1,localhost"
export no_proxy="$NO_PROXY"

# Optional IM bridge (dsh-wsl-im): WeCom/Feishu/… credentials
if [[ -f "${HOME}/.dsh/dsh-wsl-im.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  # strip CRLF if file edited on Windows
  # shellcheck disable=SC1090
  source <(tr -d '\r' < "${HOME}/.dsh/dsh-wsl-im.env")
  set +a
fi

# Optional Jev / System One (dsh-wsl-jev): OpenRouter or TypeSafe key
if [[ -f "${HOME}/.dsh/dsh-wsl-jev.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source <(tr -d '\r' < "${HOME}/.dsh/dsh-wsl-jev.env")
  set +a
fi

pkill -f 'node.*/dsh web' 2>/dev/null || true
pkill -f 'dsh-port-relay.py' 2>/dev/null || true
sleep 1

setsid nohup dsh web --no-open --port 3080 --trusted-host 127.0.0.1:3081 \
  >> /tmp/dsh-web.log 2>&1 < /dev/null &
DSH_PID=$!
echo "spawned shell pid=$DSH_PID"
sleep 4
REAL="$(pgrep -n -f 'node.*/dsh web' || true)"
echo "node pid=${REAL:-none}"
ss -tlnp | grep 3080 || echo "no 3080 yet"

for i in 1 2 3 4 5 6; do
  sleep 5
  if pgrep -f 'node.*/dsh web' >/dev/null; then
    echo "t=$((i*5))s alive code=$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://127.0.0.1:3080/ || echo fail)"
  else
    echo "t=$((i*5))s DEAD"
    tail -20 /tmp/dsh-web.log
    exit 1
  fi
done

sed 's/\r$//' /mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-wsl-kit/scripts/dsh-port-relay.py > /tmp/dsh-port-relay.py
setsid nohup python3 /tmp/dsh-port-relay.py >> /tmp/dsh-relay.log 2>&1 < /dev/null &
sleep 1
echo "relay=$(pgrep -n -f dsh-port-relay.py || echo none)"
curl --noproxy '*' -s -o /dev/null -w "3080=%{http_code} " --connect-timeout 3 http://127.0.0.1:3080/ || echo -n "3080=fail "
curl --noproxy '*' -s -o /dev/null -w "3081=%{http_code}\n" --connect-timeout 3 http://127.0.0.1:3081/ || echo "3081=fail"
# shellcheck source=dsh-web-alive.inc.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/dsh-web-alive.inc.sh"
ui="$(dsh_write_ui_url /tmp/dsh-web.log)"
echo "OK — open ${ui}"
echo "(dsh ≥0.1.2: bare :3081 is 401; token is one-shot per process, also in /tmp/dsh-ui-url)"
