#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"
export NO_PROXY="127.0.0.1,localhost,${NO_PROXY:-}"
export no_proxy="$NO_PROXY"

RELAY_SRC="/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-wsl-kit/scripts/dsh-port-relay.py"

pkill -f 'node.*/dsh web' 2>/dev/null || true
pkill -f 'dsh-port-relay.py' 2>/dev/null || true
sleep 1

nohup dsh web --no-open --port 3080 > /tmp/dsh-web.log 2>&1 &
sleep 5
if ! pgrep -f 'node.*/dsh web' >/dev/null; then
  echo "dsh failed:"; cat /tmp/dsh-web.log; exit 1
fi

sed 's/\r$//' "$RELAY_SRC" > /tmp/dsh-port-relay.py
nohup python3 /tmp/dsh-port-relay.py > /tmp/dsh-relay.log 2>&1 &
sleep 1

ss -tlnp | grep -E '3080|3081' || true
curl --noproxy '*' -s -o /dev/null -w "3080=%{http_code} 3081=%{http_code}\n" http://127.0.0.1:3080/ http://127.0.0.1:3081/ || true
echo "Windows browser: http://127.0.0.1:3081  (NOT :3000)"
