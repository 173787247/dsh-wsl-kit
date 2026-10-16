#!/usr/bin/env bash
# dsh-web-watchdog.sh —— 只在 dsh web 真的不通时才动手。
#
# ★ 为什么需要它
#   「dsh 死了」这件事原来没有任何东西会发现：
#     · 保活件只管【开浏览器】，不管【起 dsh】
#     · 桌面按钮能起，但要人去点
#     · dsh-web.service 是 oneshot + RemainAfterExit，进程逃出单元后它也无能为力
#   ⇒ 所以一次意外退出就变成「等人来救」。
#
# ★ 它凭什么不会和别的东西抢
#   3080 应答（401 也算活）⇒ 直接退出，什么都不做。
#   而这正是 revive-dsh.sh 里那个守卫的同一个判据 ⇒ 两层都不会起第二份。
#
# ★ 退避
#   真坏了的时候（比如包半装）不要每 60 秒重试一次 ——
#   那样只会刷日志、并让机器一直忙。同一原因 5 分钟内只试一次。
set -uo pipefail

export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NO_PROXY="127.0.0.1,localhost${NO_PROXY:+,${NO_PROXY}}"
export no_proxy="$NO_PROXY"

KIT="${DSH_WSL_KIT:-$HOME/src/dsh-wsl-kit}"
PORT="${DSH_WEB_PORT:-3080}"
LOGDIR="${HOME}/.dsh/logs"
LOG="${LOGDIR}/dsh-web-watchdog.log"
STAMP="${LOGDIR}/dsh-web-watchdog.last-revive"
BACKOFF="${DSH_WATCHDOG_BACKOFF:-300}"
mkdir -p "$LOGDIR"

# ★ 不要写 `|| echo 000`：curl 连不上时自己就会打 000，再接一个 echo 就变成
#   "000000"（2026-10-16 实测）。判断不受影响，但日志会骗人。
code="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 5 \
        "http://127.0.0.1:${PORT}/" 2>/dev/null)"
code="${code:-000}"
case "$code" in
  200|301|302|303|401) exit 0 ;;      # 活着 —— 常态，不写日志
esac

now="$(date +%s)"
if [[ -f "$STAMP" ]]; then
  last="$(cat "$STAMP" 2>/dev/null || echo 0)"
  if [[ "$((now - last))" -lt "$BACKOFF" ]]; then
    exit 0                            # 刚试过，退避中
  fi
fi
printf '%s' "$now" > "$STAMP"

printf '%s  :%s ⇒ %s ⇒ 起 revive（退避 %ss）\n' \
  "$(date '+%F %T')" "$PORT" "$code" "$BACKOFF" >> "$LOG"
bash "${KIT}/scripts/revive-dsh.sh" --quiet >> "$LOG" 2>&1
rc=$?
printf '%s  revive 退出码 %s\n' "$(date '+%F %T')" "$rc" >> "$LOG"
exit 0
