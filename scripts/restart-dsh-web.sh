#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
pkill -f 'node.*/dsh web' 2>/dev/null || true
sleep 1
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"
nohup dsh web --no-open > /tmp/dsh-web.log 2>&1 &
sleep 5
echo "processes:"
pgrep -af 'node.*/dsh' || echo "(none)"
PID="$(pgrep -n -f 'node.*/dsh web' || true)"
echo "PID=${PID:-}"
if [[ -n "${PID}" ]]; then
  echo "env:"
  tr '\0' '\n' < "/proc/${PID}/environ" | grep -E 'NODE_USE_ENV_PROXY|HTTP_PROXY|HTTPS_PROXY|OLLAMA' || true
fi
curl -s -o /dev/null -w "http=%{http_code}\n" http://127.0.0.1:3080/ || true
echo "---log---"
tail -30 /tmp/dsh-web.log || true
