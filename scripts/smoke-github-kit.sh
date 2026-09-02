#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
echo "=== github env files ==="
ls -la "${HOME}/.dsh/"*github* 2>/dev/null || echo none
echo "=== install github set ==="
sed 's/\r$//' /mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-wsl-kit/install.sh > /tmp/install-kit.sh
KIT_SET=github bash /tmp/install-kit.sh
echo "=== plugins ==="
dsh plugin --profile web list 2>&1 | sed -n '/dependencies:/,/packages/p'
