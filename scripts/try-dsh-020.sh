#!/usr/bin/env bash
# try-dsh-020.sh —— 让新版 0.2.0-rc.1 接管 3080，旧版文件不动
#
# 目的：验证新版能不能跑【我们自己的会话】。
#   一个会话同时只能被一个实例持有，所以必须先把旧版停掉。
#
# ★ 安全性：全程不碰 ~/.local 里的旧版。PATH 里的 dsh 仍是 0.1.7-alpha.2，
#   所以桌面快捷方式 / restart-dsh-web-detached.sh 起来的一定是旧版。
#
# 用法（必须用 systemd-run，否则停 3080 会连带杀掉发起它的 shell）：
#   systemd-run --user --collect --unit=dsh-020-try-$(date +%H%M%S) \
#     --property=KillMode=process \
#     /bin/bash ~/src/dsh-wsl-kit/scripts/try-dsh-020.sh
set -uo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"
export NO_PROXY="127.0.0.1,localhost" no_proxy="127.0.0.1,localhost"
for f in "$HOME/.dsh/dsh-wsl-im.env" "$HOME/.dsh/dsh-wsl-jevo.env" "$HOME/.dsh/dsh-wsl-jev.env"; do
  [ -f "$f" ] && { set -a; source <(tr -d '\r' < "$f") 2>/dev/null; set +a; }
done

NEW="${HOME}/.local/dsh-020"
BIN="$NEW/node_modules/@deepseek-ai/dsh/lib/bin.js"
PORT="${DSH_WEB_PORT:-3080}"
RELAY="${DSH_RELAY_PORT:-3081}"
LOG="/tmp/dsh-web-020.log"

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; }

log "════ 新版接管 $PORT ════"
log "  新版 $BIN"
log "  版本 $(node -e "console.log(require('$NEW/node_modules/@deepseek-ai/dsh/package.json').version)" 2>/dev/null)"
log "  ★ 旧版文件不动，PATH 里的 dsh 仍是旧版 → 桌面随时能救"

# ── 1 停旧版（只停这个端口）
log "════ 1/4 停旧版（端口 $PORT） ════"
pkill -f "dsh web .*--port ${PORT}([^0-9]|\$)" 2>/dev/null || true
sleep 3
if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
  log "  ★ 端口还占着，强制"
  for p in $(ss -ltnp 2>/dev/null | grep ":${PORT} " | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u); do
    kill -9 "$p" 2>/dev/null || true
  done
  sleep 2
fi
log "  $PORT 已释放: $(ss -ltn 2>/dev/null | grep -c ":${PORT} ") 个监听"

# ── 2 用新版起同一个端口（relay 不动，它只是转发）
log "════ 2/4 起新版到 $PORT ════"
: > "$LOG"
setsid nohup node "$BIN" web --no-open --port "$PORT" \
  --trusted-host "127.0.0.1:${RELAY}" >> "$LOG" 2>&1 < /dev/null &
log "  已发起"

# ── 3 等它起来
log "════ 3/4 等就绪 ════"
UP=0
for i in $(seq 1 30); do
  sleep 2
  code=$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 "http://127.0.0.1:${PORT}/" 2>/dev/null)
  if [ "$code" = "401" ] || [ "$code" = "303" ]; then log "  ✓ $((i*2))s 后就绪（HTTP $code）"; UP=1; break; fi
  [ $((i % 5)) -eq 0 ] && log "  ... $((i*2))s  code=$code"
done

if [ "$UP" != "1" ]; then
  log "  ★★ 新版没起来 —— 回退到旧版"
  tail -20 "$LOG" | sed 's/^/     /'
  bash "${HOME}/src/dsh-wsl-kit/scripts/restart-dsh-web-detached.sh" || true
  exit 1
fi

# ── 4 写 URL 并开浏览器
log "════ 4/4 抓 token 并开浏览器 ════"
url="$(grep -aoE "http://127\.0\.0\.1:${RELAY}/\?token=[A-Za-z0-9._~-]+" "$LOG" | tail -1 || true)"
if [ -n "$url" ]; then
  printf '%s\n' "$url" > /tmp/dsh-ui-url
  log "  $url"
  # 用与 start-dsh-web.ps1 相同的方式开（Windows shell → 默认浏览器）
  url_b64="$(printf '%s' "$url" | base64 -w0)"
  ps="\$u=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('${url_b64}')); Start-Process \$u"
  powershell.exe -NoProfile -NonInteractive -EncodedCommand \
    "$(printf '%s' "$ps" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)" >/dev/null 2>&1 || true
  log "  已开浏览器"
else
  log "  ★ 没抓到 token —— 看 $LOG"
fi

log "════ 完成 ════"
log "  3080 现在跑的是: $(node -e "console.log(require('$NEW/node_modules/@deepseek-ai/dsh/package.json').version)" 2>/dev/null)"
log "  失败回退: bash ~/src/dsh-wsl-kit/scripts/restart-dsh-web-detached.sh"
log "            （或点桌面 DSH WSL —— 等效，起的是旧版）"
