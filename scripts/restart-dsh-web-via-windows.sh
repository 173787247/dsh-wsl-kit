#!/usr/bin/env bash
# restart-dsh-web-via-windows.sh —— 请【Windows 侧】去重启 dsh web，让它活得过这次重启
#
# ★ 为什么不能在 WSL 侧用 systemd 发起
#   实测两次：这类重启会重建 systemd --user 实例，于是它名下所有单元里的进程一起死 ——
#   包括刚刚被拉起来的 dsh web 本身。判据：
#       journalctl --user | grep -oE 'systemd\[[0-9]+\]' | sort -u
#   出现多个 manager PID ⇒ 管理器被重建过 ⇒ 它名下的进程都活不过去。
#   现场旁证：同一个 manager 单元里起的取样进程，本该采样 44 次，只写出 4 次就没了。
#   能活下来的只有【Windows 侧拉起的进程】—— 父进程链最终落到 Windows 侧的 Relay。
#
# ★ 所以这个脚本只做一件事：请 Windows 侧去跑托盘那份 PS1。
#   它在那边执行，进程与 Relay 同源；它再调 revive-dsh.sh 做逐层诊断与修复，
#   并从 Windows 侧打开带 token 的页面 —— 那一步只有 Windows 能做
#   （从 systemd 单元里调 powershell Start-Process，退出码 0 但浏览器不出现）。
#
# ★ 必须用 Start-Process 再分离一层：否则那个 PowerShell 会随发起它的互操作调用一起死。
#
# 用法：
#   bash restart-dsh-web-via-windows.sh          # 发起重启（发起方会话会断，正常）
#   bash restart-dsh-web-via-windows.sh --dry    # 只打印将要执行的命令
set -uo pipefail

DRY=0
[ "${1:-}" = "--dry" ] && DRY=1

PS1_LINUX="${HOME}/.dsh/tray/start-dsh-web.ps1"
if [[ ! -f "$PS1_LINUX" ]]; then
  echo "找不到 ${PS1_LINUX} —— 先安装托盘（install-tray）" >&2
  exit 1
fi
command -v wslpath >/dev/null 2>&1 || { echo "wslpath 不可用：本脚本要在 WSL 里跑" >&2; exit 1; }
command -v powershell.exe >/dev/null 2>&1 || {
  echo "powershell.exe 不可达：Windows 互操作没开，或 PATH 里没有 Windows 目录" >&2; exit 1; }

PS1_WIN="$(wslpath -w "$PS1_LINUX" 2>/dev/null)" || { echo "wslpath -w 失败" >&2; exit 1; }
# PowerShell 的单引号字符串里，单引号要写成两个
PS1_WIN_Q="${PS1_WIN//\'/\'\'}"

CMD="Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','${PS1_WIN_Q}' -WindowStyle Minimized"

echo "将在【Windows 侧】执行："
echo "  ${CMD}"
echo
echo "  被执行的 PS1：${PS1_LINUX}"
echo "  它接下来会：调 revive-dsh.sh（逐层诊断 → 必要时修 → 起 dsh web + 中继 → 等端口真的应答）"
echo "              → 在 Windows 侧打开带 token 的页面"
echo "  发起方会话会断，这是预期；服务由 Windows 侧负责起回来，不依赖发起方活着。"
if [[ "$DRY" == 1 ]]; then echo; echo "（--dry：到此为止）"; exit 0; fi

powershell.exe -NoProfile -Command "$CMD" || { echo "调用 powershell.exe 失败" >&2; exit 1; }
echo "已移交 Windows 侧。"
