#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:${PATH}"
dsh plugin --profile web add /mnt/c/Users/<you>/Desktop/AIFullStackDevelopment/dsh-wsl-secret
echo "=== plugins ==="
dsh plugin --profile web list | grep dsh-wsl- || true
echo "=== log ==="
grep -E 'dsh-wsl-(ollama|media|search|vecmem|k8s|secret)' /tmp/dsh-web.log | tail -40 || true
