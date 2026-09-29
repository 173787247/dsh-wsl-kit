#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
# ★ 读【本仓】的 install.sh —— 原先硬编码到 Windows 侧的一份旧副本，
#   那份已经落后于这里，脚本会跑到过时的安装集。
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "=== github env files ==="
ls -la "${HOME}/.dsh/"*github* 2>/dev/null || echo none
echo "=== install github set ==="
sed 's/\r$//' "${KIT_DIR}/install.sh" > /tmp/install-kit.sh
KIT_SET=github bash /tmp/install-kit.sh
echo "=== plugins ==="
dsh plugin --profile web list 2>&1 | sed -n '/dependencies:/,/packages/p'
