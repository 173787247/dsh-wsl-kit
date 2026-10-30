#!/usr/bin/env bash
# 三个 cordis 补丁 —— 线上 cordis 的真实缺陷
#
# 缺陷：插件在 update 时抛异常 → 逃逸成 unhandled rejection → 【进程被打死】。
#       差分验证：打补丁前 15 agreed + i5 场景崩溃；打补丁后 19 agreed，零回归。
#
# 来源：~/src/cordis-dsh-audit/backport/*.patch（2026-09-28 差分验证过）
set -uo pipefail
LIVE="${DSH:-$HOME/.local/lib/node_modules/@deepseek-ai/dsh}/node_modules/@deepseek-ai"
BACKPORT="${BACKPORT:-$HOME/src/cordis-dsh-audit/backport}"

cd "$LIVE" || { echo "  ★ 找不到 $LIVE"; exit 1; }
applied=0; skipped=0; failed=0

apply_one() {
  local f="$1" n
  n=$(basename "$f")
  # 已经打过？（反向 dry-run 能过 = 已应用）
  if patch -p1 -R --dry-run < "$f" >/dev/null 2>&1; then
    echo "  $n 已打过，跳过"; skipped=$((skipped+1)); return
  fi
  if patch -p1 --dry-run < "$f" >/dev/null 2>&1; then
    if patch -p1 < "$f" >/dev/null 2>&1; then
      echo "  $n 已重打"; applied=$((applied+1))
    else
      echo "  ★ $n 打补丁失败"; failed=$((failed+1))
    fi
  else
    echo "  ★ $n 打不上 —— 新版 cordis 的代码变了，需要重新做适配"
    failed=$((failed+1))
  fi
}

# 基础 patch（版本号后直接 .patch）先打，带后缀的适配 patch 后打；否则后缀
# patch 改了上下文，基础 patch 会被误判为「打不上」。
for pass in base extra; do
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    n=$(basename "$f")
    if [[ "$n" =~ ^[a-z][a-z0-9.-]*-[0-9]+(\.[0-9]+)+\.patch$ ]]; then
      kind=base
    else
      kind=extra
    fi
    [ "$pass" = "$kind" ] || continue
    apply_one "$f"
  done < <(printf '%s\n' "$BACKPORT"/*.patch | sort)
done
echo "  重打 $applied · 跳过 $skipped · 失败 $failed"
[ "$failed" -eq 0 ] || exit 1
