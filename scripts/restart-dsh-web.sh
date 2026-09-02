#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"
export NO_PROXY="127.0.0.1,localhost,${NO_PROXY:-}"
export no_proxy="$NO_PROXY"

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
echo "OK — open http://127.0.0.1:3081/"
