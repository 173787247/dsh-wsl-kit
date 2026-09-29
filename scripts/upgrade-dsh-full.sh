#!/usr/bin/env bash
# upgrade-dsh-full.sh —— 升级 dsh，并把我们的本地定制重新应用回去
#
# ★ 为什么不能只跑官方的 `npm install -g`
#   那会覆盖整个 node_modules，我们改过的东西全没了 ——
#   而「每次升级都重头再来」不是进化，是原地打转。
#   所以：备份 → 升级 → 重打本地定制 → 逐条验证 → 起回来；失败自动回滚。
#
# ★ 为什么要一个脚本而不是几步
#   升级会 pkill 掉 dsh web（也就是发命令的这个会话）。
#   所以整条链必须在【一个独立进程】里跑完，否则中间断了就剩一个没有 dsh 的状态。
#
# 用法：
#   bash upgrade-dsh-full.sh 0.2.0-rc.1          # 升级到指定版本
#   bash upgrade-dsh-full.sh --dry 0.2.0-rc.1    # 只打印计划，不动
#
# ★ 必须用 systemd-run 起独立单元，否则会被工具调用的进程组清理带走：
#   systemd-run --user --collect --unit=dsh-upgrade-$(date +%H%M%S) \
#     --property=KillMode=process \
#     /bin/bash ~/src/dsh-wsl-kit/scripts/upgrade-dsh-full.sh 0.2.0-rc.1
set -uo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE="${HOME}/.local/lib/node_modules/@deepseek-ai/dsh"
DETACHED="$HERE/restart-dsh-web-detached.sh"

DRY=0
[ "${1:-}" = "--dry" ] && { DRY=1; shift; }
TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "用法: $0 [--dry] <版本，如 0.2.0-rc.1>"; exit 2; }

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; }

log "════ 计划 ════"
log "  目标版本   $TARGET"
log "  当前版本   $(dsh --version 2>/dev/null || echo unknown)"
log "  安装位置   $LIVE"
log "  流程       备份 → 升级 → 重打本地定制 → 验证 → 起回来"
log "  失败处理   自动回滚到备份"
if [ "$DRY" = 1 ]; then log "  ★ --dry：到此为止"; exit 0; fi

# ── 1 备份 ─────────────────────────────────────────────────────────────────
BK="${HOME}/.dsh/dsh-upgrade-backup-$(date +%Y%m%d_%H%M%S)"
log "════ 1/6 备份到 $BK ════"
mkdir -p "$BK"
cp -r "$LIVE" "$BK/dsh-before" 2>/dev/null && log "  ✓ dsh 包"
cp "$HOME/.dsh/profiles/web/cordis.patch.yml" "$BK/" 2>/dev/null && log "  ✓ cordis.patch.yml"
cp -r "$HOME/src/cordis-dsh-audit/backport" "$BK/backport" 2>/dev/null && log "  ✓ backport/*.patch"
dsh --version > "$BK/version-before.txt" 2>&1 || true
echo "$BK" > /tmp/dsh-upgrade-backup-path

# ── 2 停 ───────────────────────────────────────────────────────────────────
log "════ 2/6 停 dsh web（发命令的会话会断，正常） ════"
pkill -f 'dsh web' 2>/dev/null || true
pkill -f 'dsh-port-relay' 2>/dev/null || true
sleep 3

# ── 3 升级 ─────────────────────────────────────────────────────────────────
log "════ 3/6 安装 @deepseek-ai/dsh@$TARGET ════"
if npm install -g --prefix "${HOME}/.local" "@deepseek-ai/dsh@${TARGET}" 2>&1 | tail -4; then
  log "  ✓ 新版本 $(dsh --version 2>/dev/null || echo unknown)"
else
  log "  ★ 安装失败 —— 回滚"
  rm -rf "$LIVE"; cp -r "$BK/dsh-before" "$LIVE"
  log "  ✓ 已回滚到 $(dsh --version 2>/dev/null || echo unknown)"
  bash "$DETACHED" >> /tmp/dsh-upgrade.log 2>&1
  exit 1
fi

# ── 4 ★ 重打本地定制（这一步是关键，不能跳） ────────────────────────────────
log "════ 4/6 重打本地定制 ════"
if bash "$HERE/apply-local-patches.sh" 2>&1 | sed 's/^/  /'; then
  log "  ✓ 全部本地定制已生效"
else
  log "  ★ 有定制没打上 —— 见上面输出"
  log "  ★ 这不一定是致命的，但升级【不算完成】。"
  log "  ★ 详情：bash $HERE/apply-local-patches.sh --check"
fi

# ── 5 起回来 ───────────────────────────────────────────────────────────────
log "════ 5/6 起回 dsh web ════"
bash "$DETACHED" >> /tmp/dsh-upgrade.log 2>&1
sleep 14
log "  pid $(pgrep -f 'dsh web .*--port 3080' | head -1)"

# ── 6 总结 ─────────────────────────────────────────────────────────────────
log "════ 6/6 总结 ════"
log "  版本      $(dsh --version 2>/dev/null || echo unknown)"
log "  dsh web   $(pgrep -f 'dsh web .*--port 3080' | head -1 || echo '★ 没起来')"
log "  备份      $BK"
log "  回滚      rm -rf $LIVE && cp -r $BK/dsh-before $LIVE"
log "  日志      /tmp/dsh-upgrade.log"
log "════ 完成 ════"
