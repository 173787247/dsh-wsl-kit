#!/usr/bin/env bash
# 公开仓隐私检查 —— 扫【已跟踪文件】里不该公开的内容。只读，退出码 1 = 有发现，2 = 没扫到东西。
#
# 用法: bash scripts/check-privacy.sh [仓根]
#   ★ 缺省扫本仓；给一个检出根（自己不是仓、下面是一堆 dsh-* 仓）时逐个扫。
#
# 三条纪律，都是踩过的坑：
#   1 每个 git grep 都要让 stderr 出声 —— 用 2>/dev/null 吞掉 fatal，会让脚本在
#     【什么都没查】的时候报 ✓ 无发现，而那恰恰是它存在的理由。
#   2 -P 与 -E 不能同时给，flag 必须在 pattern 之前；写在后面会被 git 当成版本号。
#   3 本文件写着下面每一条要搜的模式，必然命中自己 —— 扫之前把自己排除掉。
set -uo pipefail
ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT" || exit 2

FOUND=0
hit() { FOUND=$((FOUND+1)); printf '  ★ %s\n' "$1"; shift; for l in "$@"; do printf '       %s\n' "$(echo "$l" | cut -c1-150)"; done; }

# 见纪律 3
SELF=':!scripts/check-privacy.sh'

# 通用占位符与容器用户 —— 文档里的示例路径，不是本机泄漏。没有这份名单，真正的那两条
# 会淹在「/home/user」「Users/name」这类噪音里。
PLACEHOLDER='Users/(<|YOU|name|user|you|username|someone|USERNAME)|/home/(<|user|username|you|yourname|someone|dshprobe)|LICENSE|Copyright|test/|\.test\.'

# 扫【当前目录】这一个仓
scan() {
  local r
  # ① 真 token / 密钥形态
  r=$(git grep -nIE 'token=[A-Za-z0-9_-]{12,}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}' -- . "$SELF" |
      grep -viE 'test/|\.test\.|example|placeholder|<\w+>' | head -5)
  [ -n "$r" ] && hit "疑似真 token/密钥 ($PWD):" "$r"

  # ② 本机用户名与家目录路径（见纪律 2：前瞻是 PCRE，-E 会报 Invalid preceding regular expression）
  r=$(git grep -nP '/(mnt/c/Users|home)/(?!<)[a-z][a-z0-9_-]+' -- . "$SELF" |
      grep -viE "$PLACEHOLDER" | head -5)
  [ -n "$r" ] && hit "硬编码本机用户路径 ($PWD):" "$r"

  # ③ 本机主机名 / 机器规格
  # 只写品牌与「数字+内存单位」这类形状，不写具体型号和容量 —— 否则这份模式表本身
  # 就把这台机器的配置公布在公开仓里了，正是这一条要防的事。
  r=$(git grep -nIE '\b(ASUS|MSI|Gigabyte|ASRock|Ryzen|Threadripper|Xeon|Core i[3579])\b|[0-9]{2,3}(\.[0-9])?\s*GB\s*(RAM|内存|memory)|\bWindows 11 (专业版|Pro)\b' -- . "$SELF" | head -4)
  [ -n "$r" ] && hit "本机机器信息 ($PWD):" "$r"

  # ④ 被跟踪的敏感文件名
  r=$(git ls-files | grep -iE '(^|/)\.env$|\.pem$|id_rsa|\.key$|credentials?\.(json|ya?ml)$' |
      grep -viE 'example|sample|template' | head -5)
  [ -n "$r" ] && hit "被跟踪的敏感文件名 ($PWD):" "$r"

  # ⑤ 个人邮箱（非仓库归属）
  r=$(git grep -nIE '[A-Za-z0-9._%+-]+@(gmail|qq|163|126|outlook|hotmail|foxmail)\.com' -- . "$SELF" |
      grep -viE 'noreply|example|test@' | head -4)
  [ -n "$r" ] && hit "个人邮箱 ($PWD):" "$r"
}

# 检出根自己不是仓时，把下面的 dsh-* 仓逐个扫。少了这一步，每个 git grep 都会死在
# `fatal: not a git repository`，而脚本会以 ✓ 无发现 收场（见纪律 1）。
TARGETS=()
if git rev-parse --git-dir >/dev/null 2>&1; then
  TARGETS=("$PWD")
else
  for d in "$ROOT"/dsh-*/; do
    [ -d "$d/.git" ] || continue
    TARGETS+=("${d%/}")
  done
fi
if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "  ★ $ROOT 既不是 git 仓，下面也没有 dsh-* 仓 —— 没有可扫的东西"
  exit 2
fi

for t in "${TARGETS[@]}"; do
  cd "$t" || { echo "  ★ 进不去 $t"; exit 2; }
  scan
done

echo "  扫了 ${#TARGETS[@]} 个仓（$ROOT）"
if [ "$FOUND" = "0" ]; then
  echo "  ✓ 无发现"
  exit 0
fi
echo "  ★ 共 $FOUND 类发现"
exit 1
