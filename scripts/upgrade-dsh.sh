#!/usr/bin/env bash
set -uo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY="${NODE_USE_ENV_PROXY:-1}"

echo "BEFORE: $(dsh --version 2>/dev/null || echo unknown)"
echo "Stopping dsh web / relay..."
pkill -f 'dsh web' 2>/dev/null || true
pkill -f 'dsh-port-relay' 2>/dev/null || true
sleep 2
if pgrep -af 'dsh web' >/dev/null 2>&1; then
  echo "WARN: dsh still running:"
  pgrep -af 'dsh web' || true
fi

TARGET="${1:-next}"
echo "Installing @deepseek-ai/dsh@${TARGET} ..."
npm install -g --prefix "${HOME}/.local" "@deepseek-ai/dsh@${TARGET}"
echo "AFTER: $(dsh --version)"
npm ls -g --prefix "${HOME}/.local" --depth=0
