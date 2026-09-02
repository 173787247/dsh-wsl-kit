#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY=ollama
pkill -f 'node.*/dsh web' 2>/dev/null || true
sleep 1
HOST_IP="$(ip -4 -br addr show eth2 2>/dev/null | awk '{print $3}' | cut -d/ -f1 || true)"
echo "HOST_IP=${HOST_IP}"
if [[ -z "$HOST_IP" ]]; then
  HOST_IP="$(hostname -I | awk '{print $1}')"
fi
echo "Trying --host ${HOST_IP}"
nohup dsh web --no-open --host "$HOST_IP" --port 3080 > /tmp/dsh-web.log 2>&1 &
sleep 5
cat /tmp/dsh-web.log
ss -tlnp | grep 3080 || true
pgrep -af 'dsh web' || echo DOWN
