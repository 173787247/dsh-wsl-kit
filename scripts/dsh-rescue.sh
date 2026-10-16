#!/usr/bin/env bash
# dsh-rescue.sh —— 最后一道：不管坏成什么样，尽量把 dsh web 叫起来。
#
# ★ 它和「DSH WSL」的区别
#   「DSH WSL」是日常按钮：活着就直接开页面，不活着就交给 systemd。
#   这个脚本是【万一 systemd 那条路本身坏了】用的 ⇒ 它不假设任何东西是好的：
#     ① 先试 kit 的 revive-dsh.sh（分层修复：包 → 软链 → 依赖树 → 本地定制 → 起服务）
#     ② 它不在、或跑完仍然不通 ⇒ 用【内联最小步骤】硬起一份，不依赖任何 kit 脚本
#     ③ 再不通 ⇒ 把「为什么」逐条打出来，让人能把它发给下一个会话
#
# ★ 它故意【不】判断"已经活着就别动" —— 那是日常按钮的职责。
#   但它在动手前会说清楚现在是什么状态，免得人不知道它做了什么。
set -uo pipefail

export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export NO_PROXY="127.0.0.1,localhost"
export no_proxy="$NO_PROXY"

HOME_DIR="${HOME}"
KIT="${DSH_WSL_KIT:-${HOME}/src/dsh-wsl-kit}"
WEB="${DSH_WEB_PORT:-3080}"
RELAY="${DSH_RELAY_PORT:-3081}"
URLFILE="${DSH_UI_URL_FILE:-/tmp/dsh-ui-url}"
WEBLOG="${DSH_WEB_LOG:-/tmp/dsh-web.log}"
STAGE="/tmp/dsh-rescue-stage.txt"

say()  { printf '%s\n' "$*"; }
head_() { printf '\n== %s ==\n' "$*"; }
up()   { case "${1:-}" in 200|301|302|303|401) return 0 ;; *) return 1 ;; esac; }
code_of() { curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 4 "http://127.0.0.1:${1}/" 2>/dev/null; }

: > "$STAGE"
step() { printf '%s\n' "$*" | tee -a "$STAGE"; }

step "dsh 急救 $(date '+%F %T')"
step "  发行版   ${WSL_DISTRO_NAME:-未知}"
step "  dsh      $(command -v dsh 2>/dev/null || echo '★ 不在 PATH')  $("$HOME_DIR/.local/bin/dsh" --version 2>/dev/null || echo '(版本取不到)')"
step "  端口     :${WEB}（web） · :${RELAY}（中继）"

head_ "1 现在通不通"
c="$(code_of "$WEB")"; r="$(code_of "$RELAY")"
step "  :${WEB} ⇒ ${c:-000}    :${RELAY} ⇒ ${r:-000}"

if ! up "$c"; then
  head_ "2 起 dsh web"
  if [[ -f "$KIT/scripts/revive-dsh.sh" ]]; then
    step "  ① 用 kit 的 revive-dsh.sh（分层修复）"
    bash "$KIT/scripts/revive-dsh.sh" 2>&1 | sed 's/^/     /' | tee -a "$STAGE"
  else
    step "  ① ★ 没有 $KIT/scripts/revive-dsh.sh —— 跳过，直接走内联"
  fi
  c="$(code_of "$WEB")"

  if ! up "$c"; then
    head_ "3 内联最小步骤（不依赖任何 kit 脚本）"
    BIN="$HOME_DIR/.local/bin/dsh"
    if [[ ! -x "$BIN" && ! -f "$BIN" ]]; then
      step "  ★ $BIN 不存在 ⇒ 这一步也做不了"
      step "    包可能在 ~/.local/lib/node_modules/@deepseek-ai/dsh，但入口没了"
      step "    要重装： npm install -g --prefix \"\$HOME/.local\" @deepseek-ai/dsh@<版本>"
    else
      step "  ② 直接起： setsid nohup dsh web --no-open --port ${WEB} …"
      ( cd "$HOME_DIR" && setsid nohup "$BIN" web --no-open --port "$WEB" \
          --trusted-host "127.0.0.1:${RELAY}" >"$WEBLOG" 2>&1 & ) 2>/dev/null
      for i in $(seq 1 45); do
        c="$(code_of "$WEB")"; up "$c" && break
        sleep 2
      done
      step "  ⇒ :${WEB} = ${c:-000}"
    fi
  fi
fi

# ── 中继（入口是 :3081，裸 :3080 也能用，但日常入口是中继）
if up "$(code_of "$WEB")" && ! up "$(code_of "$RELAY")"; then
  head_ "4 起 :${RELAY} 中继"
  R="/tmp/dsh-port-relay-${RELAY}.py"
  if [[ -f "$R" ]]; then
    ( setsid nohup python3 "$R" --listen "$RELAY" --target "$WEB" >>"$WEBLOG" 2>&1 & ) 2>/dev/null
    for i in $(seq 1 15); do up "$(code_of "$RELAY")" && break; sleep 1; done
    step "  ⇒ :${RELAY} = $(code_of "$RELAY")"
  else
    step "  ★ 没有 $R ⇒ 用 :${WEB} 直连也一样（只是入口端口不同）"
  fi
fi

# ── 结果：把带 token 的 URL 交出来
head_ "5 结果"
c="$(code_of "$WEB")"; r="$(code_of "$RELAY")"
step "  :${WEB} ⇒ ${c:-000}    :${RELAY} ⇒ ${r:-000}"
step "  dsh web pid: $(pgrep -f "dsh web .*--port ${WEB}" 2>/dev/null | head -1 || echo 无)"

URL=""
[[ -f "$URLFILE" ]] && URL="$(tr -d '\r\n' < "$URLFILE" 2>/dev/null || true)"
if [[ "$URL" != *token=* ]]; then
  URL="$(grep -aoE "http://127\.0\.0\.1:[0-9]+/\?token=[A-Za-z0-9._~-]+" "$WEBLOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$URL" ]] && printf '%s\n' "$URL" > "$URLFILE"
fi
if [[ "$URL" == *token=* ]]; then
  step "  URL: ${URL%%token=*}token=<隐藏>"
  printf '%s\n' "$URL" > /tmp/dsh-rescue-url
else
  step "  ★ 拿不到带 token 的 URL"
  step "    看 $WEBLOG 的最后几行："
  tail -5 "$WEBLOG" 2>/dev/null | sed 's/^/       /' | tee -a "$STAGE"
fi

if up "$c" || up "$r"; then exit 0; else exit 1; fi
