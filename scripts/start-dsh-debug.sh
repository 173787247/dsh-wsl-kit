#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"
# Ensure localhost bypasses proxy for dsh itself
export NO_PROXY="127.0.0.1,localhost,${NO_PROXY:-}"
export no_proxy="$NO_PROXY"

pkill -f 'node.*/dsh web' 2>/dev/null || true
sleep 1

echo "Starting dsh web..."
nohup dsh web --no-open > /tmp/dsh-web.log 2>&1 &
sleep 6
PID="$(pgrep -n -f 'node.*/dsh web' || true)"
echo "PID=${PID:-none}"
ss -tlnp | grep -E '3080|3000' || true
echo "--- log ---"
cat /tmp/dsh-web.log
echo "--- noproxy curl ---"
curl --noproxy '*' -s -o /dev/null -w "3080=%{http_code}\n" --connect-timeout 3 http://127.0.0.1:3080/ || echo fail3080
# identify :3000
echo "--- :3000 owners ---"
ss -tlnp sport = :3000 || true
