#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
echo "=== dsh web ==="
pgrep -af 'node.*/dsh web' || echo "dsh-web-down"
echo "=== plugin versions (see also check-plugin-versions.sh) ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/check-plugin-versions.sh" || true
echo "=== plugins ==="
dsh plugin --profile web list 2>&1 | sed -n '/dependencies:/,/packages/p' || true
echo "=== tray ==="
ls -la ~/.dsh/tray 2>/dev/null || echo "no-tray-dir"
echo "=== profile files ==="
ls -la ~/.dsh/profiles/web/ 2>/dev/null | head -40
echo "=== settings ollama ctx ==="
grep -A3 'qwen38-27b-local' ~/.dsh/settings.yaml | head -8 || true
echo "=== host_reach smoke ==="
node /mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-wsl-kit/scripts/run-host-reach.mjs 2>&1 | tail -30
