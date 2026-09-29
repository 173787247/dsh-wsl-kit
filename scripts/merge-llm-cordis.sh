#!/usr/bin/env bash
# Merge kit examples/cordis.llm.patch.yml into the web profile (idempotent overwrite of that file's llm section).
set -euo pipefail
PROFILE_PATCH="${HOME}/.dsh/profiles/web/cordis.patch.yml"
# ★ 读【本仓】的示例 —— 原先硬编码到 Windows 侧的一份旧副本
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${KIT_DIR}/examples/cordis.llm.patch.yml"
mkdir -p "$(dirname "$PROFILE_PATCH")"
# Profile currently uses [] — replace with llm patch array when empty or backup first.
if [[ -f "$PROFILE_PATCH" ]]; then
  cp "$PROFILE_PATCH" "${PROFILE_PATCH}.bak.$(date +%Y%m%d%H%M%S)"
fi
# Strip Windows CRLF and write
sed 's/\r$//' "$SRC" > "$PROFILE_PATCH"
echo "Wrote $PROFILE_PATCH"
cat "$PROFILE_PATCH"
