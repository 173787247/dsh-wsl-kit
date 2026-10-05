#!/usr/bin/env bash
# check-self-restart.sh —— 自重启之后核对：进程换了吗、服务回来了吗、定制还在吗
set -uo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BEFORE="${DSH_RESTART_BEFORE:-$HOME/.dsh/logs/self-restart-before.txt}"
get() { grep -m1 "^$1=" "$BEFORE" 2>/dev/null | cut -d= -f2-; }

ver="$(dsh --version 2>/dev/null | head -1)"
web="$(pgrep -f '[d]sh web --no-open --port 3080' | head -1)"
relay="$(pgrep -f '[d]sh-port-relay.*--listen 3081' | head -1)"
p80="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 4 http://127.0.0.1:3080/ 2>/dev/null || echo 000)"
p81="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 4 http://127.0.0.1:3081/ 2>/dev/null || echo 000)"
patches="$(bash "${HERE}/apply-local-patches.sh" --check >/dev/null 2>&1 && echo OK || echo BAD)"

b() { printf '  %-14s 前 %-10s 后 %-10s %s\n' "$1" "$2" "$3" "$4"; }
echo "════ 自重启核对（基线 $BEFORE） ════"
b "版本"      "$(get version)"   "$ver"   "$([ "$(get version)" = "$ver" ] && echo '✓ 没变' || echo '★ 变了')"
b "dsh web pid" "$(get web_pid)" "$web"  "$([ -n "$web" ] && [ "$(get web_pid)" != "$web" ] && echo '✓ 已换进程' || echo '✗ 还是老进程 / 没起来')"
b "中继 pid"   "$(get relay_pid)" "$relay" "$([ -n "$relay" ] && echo '✓ 在跑' || echo '✗ 没起来')"
b ":3080"     "$(get port3080)"  "$p80"   "$([ "$p80" = 401 ] && echo '✓ 活着（401 是设计如此）' || echo '✗ 无应答')"
b ":3081"     "$(get port3081)"  "$p81"   "$([ "$p81" = 401 ] && echo '✓ 活着' || echo '✗ 无应答')"
b "本地定制"   "$(get patches)"   "$patches" "$([ "$patches" = OK ] && echo '✓ 两项都在' || echo '✗ 丢了，跑 apply-local-patches.sh')"
echo
if [ "$p81" = 401 ] && [ -n "$web" ] && [ "$patches" = OK ]; then echo "结论：自重启成功 ✓"; exit 0
else echo "结论：有问题 ✗ —— 点桌面「DSH WSL」跑 revive-dsh.sh"; exit 1; fi
