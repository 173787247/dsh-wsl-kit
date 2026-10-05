#!/usr/bin/env bash
# try-dsh-rehearsal.sh <版本> —— 在隔离前缀 + 备用端口上试装新版本并验证，不碰正式实例。
#
# ★ 为什么需要它
#   正式升级必须先停 dsh web，而发起升级的那个会话就跑在它里面 —— 一停，
#   发起者就没了，后面装得对不对、起不起得来，没有任何人在场验证。
#   这个脚本把「装 + 起 + 验」搬到一个【另一个前缀、另一个端口】上先做一遍：
#   全程正式实例照常服务，验证通过后才值得去做正式切换。
#
# ★ 它保证不碰的东西
#   · 不写 $HOME/.local/lib/node_modules/@deepseek-ai/dsh（正式那份）
#   · 不起在 3080/3081 上，也不会去 kill 它们
#   · 不重打正式树里的本地定制（只在隔离前缀里打）
#
# 用法：
#   bash try-dsh-rehearsal.sh 0.2.1-alpha.1        # 试装并验证
#   bash try-dsh-rehearsal.sh 0.2.1-alpha.1 --stop # 验证完把它停掉并清理
#
# 退出码：0 = 可以切；1 = 有问题，别切。
set -uo pipefail

export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export NO_PROXY="127.0.0.1,localhost${NO_PROXY:+,${NO_PROXY}}"
export no_proxy="$NO_PROXY"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"
STOP_AFTER=0
[ "${2:-}" = "--stop" ] && STOP_AFTER=1
LIVE="${HOME}/.local/lib/node_modules/@deepseek-ai/dsh"
PREFIX="${DSH_REHEARSAL_PREFIX:-${HOME}/.local/dsh-rehearsal}"
PKG="${PREFIX}/lib/node_modules/@deepseek-ai/dsh"
LOG="${HOME}/.dsh/logs/rehearsal-$(date +%Y%m%d-%H%M%S).log"

if [[ -z "$TARGET" ]]; then echo "用法: bash try-dsh-rehearsal.sh <版本> [--stop]" >&2; exit 2; fi
[[ "$PREFIX" == *"dsh-rehearsal"* || -n "${DSH_REHEARSAL_PREFIX:-}" ]] || {
  echo "拒绝：前缀看起来不像隔离目录（$PREFIX）" >&2; exit 2; }

mkdir -p "$(dirname "$LOG")"
bad=0
say()  { printf '%s\n' "$*" | tee -a "$LOG"; }
ok()   { say "  OK    $*"; }
warn() { say "  WARN  $*"; }
fail() { say "  FAIL  $*"; bad=$((bad + 1)); }

# ── 选一对空闲端口，从 3099 往下找；3080/3081 永不使用 ────────────────────
free_port() {
  local p="${1:-3099}"
  while :; do
    [[ "$p" == "3080" || "$p" == "3081" ]] && { p=$((p + 2)); continue; }
    if ! ss -tln 2>/dev/null | grep -q ":$p "; then echo "$p"; return; fi
    p=$((p + 2)); (( p > 3200 )) && { echo 0; return; }
  done
}
WEB="$(free_port 3099)"; RELAY=$((WEB - 1))
[[ "$WEB" == "0" ]] && { echo "找不到空闲端口对" >&2; exit 2; }

say "════ dsh 升级演练 $(date '+%H:%M:%S') ════"
say "  目标版本  $TARGET"
say "  隔离前缀  $PREFIX"
say "  演练端口  :$WEB（中继 :$RELAY）"
say "  正式实例  :3080/:3081 —— 本脚本不碰"
say "  日志      $LOG"

# ── 1/6 装到隔离前缀 ─────────────────────────────────────────────────────
say ""; say "──── 1/6 装到隔离前缀 ────"
mkdir -p "$PREFIX"
if npm install -g --prefix "$PREFIX" --no-audit --no-fund "@deepseek-ai/dsh@${TARGET}" >>"$LOG" 2>&1; then
  ok "装完：$(node -p "require('${PKG}/package.json').version" 2>/dev/null || echo '版本读不出')"
else
  fail "安装失败（详见 $LOG）"; say ""; say "════ 结论：不可切 ════"; exit 1
fi

# ── 2/6 包完整性 + 依赖树完整性（正式脚本缺的就是这一项） ────────────────
say ""; say "──── 2/6 包与依赖树完整性 ────"
[[ -f "${PKG}/package.json" && -f "${PKG}/lib/bin.js" ]] && ok "包完整" || fail "缺 package.json 或 lib/bin.js"
BROKEN="$(node -e '
const fs=require("fs"),p=process.argv[1];
const names=[]; let bad=[];
for(const d of fs.readdirSync(p)){
  if(d.startsWith("."))continue;
  if(d.startsWith("@")){for(const s of fs.readdirSync(p+"/"+d)) names.push(d+"/"+s);}
  else names.push(d);
}
for(const n of names){
  const pj=p+"/"+n+"/package.json";
  if(!fs.existsSync(pj)){bad.push(n);continue;}
  try{JSON.parse(fs.readFileSync(pj,"utf8"));}catch{bad.push(n);}
}
console.log(bad.join(" "));
' "${PKG}/node_modules" 2>/dev/null || true)"
if [[ -z "${BROKEN// /}" ]]; then ok "依赖树完整（顶层包都有可解析的 package.json）"
else fail "依赖树残缺：${BROKEN}"; fi

# ── 3/6 在隔离树里重打本地定制（不碰正式树） ─────────────────────────────
say ""; say "──── 3/6 隔离树里的本地定制 ────"
if DSH="$PKG" bash "$HERE/apply-local-patches.sh" >>"$LOG" 2>&1 \
   && DSH="$PKG" bash "$HERE/apply-local-patches.sh" --check >>"$LOG" 2>&1; then
  ok "两项定制已在隔离树生效"
else
  warn "隔离树里定制未通过（正式树不受影响；此项决定切换后是否要重打）"
fi

# ── 4/6 起在演练端口 ─────────────────────────────────────────────────────
say ""; say "──── 4/6 起在 :$WEB ────"
PORT="$WEB" RELAY_PORT="$RELAY" \
  nohup "$PREFIX/bin/dsh" web --no-open --port "$WEB" --trusted-host "127.0.0.1:${RELAY}" \
  >"$HOME/.dsh/logs/rehearsal-web-${WEB}.log" 2>&1 &
WEBPID=$!
sleep 6
if kill -0 "$WEBPID" 2>/dev/null; then ok "进程活着（pid $WEBPID）"
else fail "进程 6 秒内退出 —— 看 $HOME/.dsh/logs/rehearsal-web-${WEB}.log"; fi
nohup python3 "$HERE/dsh-port-relay.py" --listen "$RELAY" --target "$WEB" \
  >"$HOME/.dsh/logs/rehearsal-relay-${RELAY}.log" 2>&1 &
sleep 2

# ── 5/6 端口真的应答（进程存在 ≠ 服务可用） ──────────────────────────────
say ""; say "──── 5/6 端口应答（401 即活） ────"
up=0
for i in $(seq 1 20); do
  code="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 3 "http://127.0.0.1:${WEB}/" 2>/dev/null || echo 000)"
  case "$code" in 200|301|302|303|401) up=1; break ;; esac
  sleep 2
done
[[ "$up" == 1 ]] && ok ":$WEB 应答 $code" || fail ":$WEB 40 秒内无应答"
r="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 3 "http://127.0.0.1:${RELAY}/" 2>/dev/null || echo 000)"
case "$r" in 200|301|302|303|401) ok ":$RELAY 应答 $r" ;; *) warn ":$RELAY 应答 $r（中继可能未起）" ;; esac

# ── 6/6 启动日志里有没有 import 失败（半装的最早信号） ────────────────────
say ""; say "──── 6/6 启动日志的 import 失败数 ────"
# ★ 只认【本次实例自己】产生的日志。
#   按 mtime 取最新是个陷阱：上一次失败升级留下的 startup-*.log 会一直是最新的，
#   于是这个检查会拿几个小时前的旧日志去判今天的演练（实测踩到，报出 149 处假失败）。
own="${HOME}/.dsh/logs/rehearsal-web-${WEB}.log"
start_ts="$(stat -c %Y "/proc/${WEBPID}" 2>/dev/null || echo 0)"
fresh=""
for f in $(ls -t "${HOME}/.dsh/logs"/startup-*.log 2>/dev/null); do
  [[ "$(stat -c %Y "$f" 2>/dev/null || echo 0)" -ge "$start_ts" ]] && { fresh="$f"; break; }
done
n_own="$(grep -icE 'failed to import|MODULE_NOT_FOUND' "$own" 2>/dev/null || true)"; n_own="${n_own:-0}"
n_fresh=0
if [[ -n "$fresh" ]]; then
  n_fresh="$(grep -icE 'failed to import|MODULE_NOT_FOUND' "$fresh" 2>/dev/null || true)"; n_fresh="${n_fresh:-0}"
fi
if [[ "$n_own" == "0" && "$n_fresh" == "0" ]]; then
  ok "0 处 import 失败（本次实例日志${fresh:+ 与 $fresh}）"
else
  fail "import 失败：实例日志 $n_own 处${fresh:+，$fresh $n_fresh 处}"
fi

# ── 收尾 ─────────────────────────────────────────────────────────────────
say ""
say "  隔离实例  :$WEB（pid ${WEBPID}）· 日志 $HOME/.dsh/logs/rehearsal-web-${WEB}.log"
say "  正式实例  :3080 未受影响 —— 可自行确认：curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3080/"
if [[ "$STOP_AFTER" == 1 ]]; then
  kill "$WEBPID" 2>/dev/null || true
  for pid in $(pgrep -f "[d]sh-port-relay.py --listen ${RELAY}" 2>/dev/null || true); do kill "$pid" 2>/dev/null || true; done
  say "  已停掉演练实例（--stop）"
fi
say ""
if [[ "$bad" == 0 ]]; then say "════ 结论：可切（验证全过）════"; exit 0
else say "════ 结论：不可切（$bad 项未过）════"; exit 1; fi
