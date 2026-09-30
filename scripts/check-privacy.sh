#!/usr/bin/env bash
# 公开仓隐私检查 —— 扫【已跟踪文件】里不该公开的内容。只读，退出码 1 = 有发现。
#
# 用法: bash scripts/check-privacy.sh [仓根]
#   ★ 默认扫本仓；也可指向别的检出根批量扫。
set -uo pipefail
ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT" || exit 2

FOUND=0
hit() { FOUND=$((FOUND+1)); printf '  ★ %s\n' "$1"; shift; for l in "$@"; do printf '       %s\n' "$(echo "$l" | cut -c1-150)"; done; }

echo "  扫 $ROOT"

# ① 真 token / 密钥形态
r=$(git grep -nIE 'token=[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}' -- . 2>/dev/null | grep -viE 'test/|\.test\.|example|placeholder|<\w+>' | head -5)
[ -n "$r" ] && hit "疑似真 token/密钥:" "$r"

# ② 本机用户名与家目录路径
r=$(git grep -nIE '/(mnt/c/Users|home)/(?!<)[a-z][a-z0-9_-]+' -P -- . 2>/dev/null | grep -viE 'Users/<|Users/YOU|/home/<|LICENSE|Copyright|test/|\.test\.' | head -5)
[ -n "$r" ] && hit "硬编码本机用户路径:" "$r"

# ③ 本机主机名 / 机器规格
r=$(git grep -nIE '\b(ASUS|Ryzen|9950X|253\.6\s*GB|Windows 11 专业版)\b' -- . 2>/dev/null | head -4)
[ -n "$r" ] && hit "本机机器信息:" "$r"

# ④ 被跟踪的敏感文件名
r=$(git ls-files | grep -iE '(^|/)\.env$|\.pem$|id_rsa|\.key$|credentials?\.(json|ya?ml)$' | grep -viE 'example|sample|template' | head -5)
[ -n "$r" ] && hit "被跟踪的敏感文件名:" "$r"

# ⑤ 个人邮箱（非仓库归属）
r=$(git grep -nIE '[A-Za-z0-9._%+-]+@(gmail|qq|163|126|outlook|hotmail|foxmail)\.com' -- . 2>/dev/null | grep -viE 'noreply|example|test@' | head -4)
[ -n "$r" ] && hit "个人邮箱:" "$r"

if [ "$FOUND" = "0" ]; then
  echo "  ✓ 无发现"
  exit 0
fi
echo "  ★ 共 $FOUND 类发现"
exit 1
