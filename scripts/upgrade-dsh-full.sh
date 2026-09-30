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
RAW="${1:-}"
[ -n "$RAW" ] || { echo "用法: $0 [--dry] <版本号 | release URL>"; exit 2; }

# ★ 也接受一个 release URL —— 因为那正是人会拿到的东西。
#   在 GitHub 的 releases 页上，能复制的是
#     https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.0-rc.2
#   而不是光秃秃的 "0.2.0-rc.2"。让人自己把 tag 从 URL 里抠出来是多此一举。
#   两个 tag 前缀都要认：release 用 `dsh-v`，npm 用裸版本号。
TARGET="$RAW"
case "$RAW" in
  http://*|https://*)
    TARGET="${RAW##*/}"                 # 取最后一段
    TARGET="${TARGET#dsh-v}"            # GitHub release 的 dsh-v 前缀
    TARGET="${TARGET#dsh-}"
    TARGET="${TARGET#v}"
    ;;
  dsh-v*) TARGET="${RAW#dsh-v}" ;;
  dsh-*)  TARGET="${RAW#dsh-}" ;;
  v*)     TARGET="${RAW#v}" ;;
esac

cd "${HOME}" || true   # ★ dsh 需要 cwd 有 package.json；kit 目录没有

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; }

log "════ 计划 ════"
log "  目标版本   $TARGET"
[ "$RAW" != "$TARGET" ] && log "             （从 $RAW 解析得到）"
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
# ★ npm 装到一半被中断会留下暂存目录 .dsh-XXXXXX，它会让【之后每一次安装】都失败：
#   ENOTEMPTY: rename 'dsh' -> '.dsh-XXXXXX'
#   （2026-09-29 实测踩到，残留的是 09-24 那个 547 MB 的 0.1.7-rc.1）
#   所以装之前先清掉。
for stale in "${LIVE%/dsh}"/.dsh-*; do
  [ -d "$stale" ] || continue
  log "  清理残留暂存目录 $(basename "$stale")（$(du -sh "$stale" 2>/dev/null | cut -f1)）"
  mv "$stale" "/tmp/stale-dsh-staging-$(date +%s)" 2>/dev/null || rm -rf "$stale"
done
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

# ★ 开浏览器必须由【Windows 侧】做，不能在 systemd 单元里做。
#
# 实测 2026-09-29：从 systemd 单元里调 powershell Start-Process，退出码 0，
# 但浏览器【不出现】—— 那是非交互式会话，到不了用户的桌面。于是升级"成功"了，
# 用户却仍要手动点桌面才能进来。重启脚本里的 dsh_open_browser 有同样的毛病。
#
# 桌面快捷方式一直是这么做的、也一直是成的：WSL 只负责重启，Windows 侧读 URL
# 再 Start-Process。所以这里调那个已经证明能用的 PS1。
log "  ── 请 Windows 侧开浏览器（systemd 里开不出来）"
# ★ 不写死发行版与用户名：用 WSL_DISTRO_NAME + 当前家目录动态拼
PS1_UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME:-Ubuntu}\\$(wslpath -w "$HOME/.dsh/tray/open-dsh-ui.ps1" 2>/dev/null || true)"
# ★ systemd 环境的 PATH 不含 Windows 路径，powershell.exe 找不到。
#   所以这里显式补上 —— 否则这一整步静默跳过，用户以为"升级后自己会开"。
for _d in /mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0 \
          /mnt/c/WINDOWS/system32 /mnt/c/WINDOWS; do
  case ":${PATH}:" in *":${_d}:"*) ;; *) [ -d "$_d" ] && PATH="${PATH}:${_d}" ;; esac
done
unset _d
if command -v powershell.exe >/dev/null 2>&1; then
  # 先写 URL，PS1 会自己从 /tmp/dsh-ui-url 读
  url="$(grep -aoE "http://127\.0\.0\.1:[0-9]+/\?token=[A-Za-z0-9._~-]+" /tmp/dsh-web.log | tail -1 || true)"
  if [ -n "$url" ]; then
    printf '%s\n' "$url" > /tmp/dsh-ui-url
    if timeout 40 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS1_UNC" >/dev/null 2>&1; then
      log "  ✓ 已请 Windows 侧打开（WSL 会话 ID 之外的进程，能到你桌面）"
    else
      log "  ★ Windows 侧调用失败 —— 点桌面 DSH WSL 即可（等效）"
    fi
  else
    log "  ★ 没抓到 token —— 点桌面 DSH WSL"
  fi
else
  log "  ★ 没有 powershell.exe —— 点桌面 DSH WSL"
fi

# ── 6 总结 ─────────────────────────────────────────────────────────────────
log "════ 6/6 总结 ════"
log "  版本      $(dsh --version 2>/dev/null || echo unknown)"
log "  dsh web   $(pgrep -f 'dsh web .*--port 3080' | head -1 || echo '★ 没起来')"
log "  备份      $BK"
log "  回滚      rm -rf $LIVE && cp -r $BK/dsh-before $LIVE"
log "  日志      /tmp/dsh-upgrade.log"
log "════ 完成 ════"
