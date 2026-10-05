#!/usr/bin/env bash
# revive-dsh.sh —— 把半装的 dsh 修回可用状态（桌面按钮调它）
#
# ★ 为什么需要它
#   一次被打断的 `npm install -g` 会同时留下三处互不相干的伤，而每一处都能
#   单独让「点桌面按钮把 dsh 拉回来」这条恢复路径失效：
#
#     ① ~/.local/bin/dsh 软链丢失（npm 只留下改名中的临时名）
#     ② 包父目录里的 .dsh-XXXXXX 暂存目录 —— 之后每次安装都 ENOTEMPTY 失败
#     ③ 依赖树残缺：某个包少了文件。它在启动时可能仍能 import，
#        却会在真正用到那条路径时失败，因此最难发现
#
#   check-dsh-health.sh 回答的是「现在活着吗」；这个脚本回答的是
#   「如果它起不来了，我能不能不看日志、不连网，就把它弄回来」。
#
# ★ 一条硬规则：这里【不联网重装】。
#   恢复依赖一律从最新的 dsh-upgrade-backup-* 里按包拷贝，补不上就明确告诉人
#   该跑什么，不自己重试 —— 安装被打断的原因通常正是网络。
#
# ★ 环回检查一律 --noproxy '*'：本脚本也可能从只有最小环境的 systemd 单元里被拉起，
#   那时 NO_PROXY 不在，curl 会把环回请求交给代理，而代理的应答会被误当成 dsh 的应答。
#
# 用法：
#   bash revive-dsh.sh                # 诊断 → 能修的修 → 起服务 → 报结果
#   bash revive-dsh.sh --no-start     # 只诊断与修复，不动正在跑的服务
#   bash revive-dsh.sh --quiet        # 少说话（给脚本调用）
#
# 退出码：0 全好；1 有没修好的东西（桌面按钮据此把窗口留着并提示）
set -uo pipefail

export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
# ★ 环回一律显式绕过代理。
#   NO_PROXY 通常已含 127.*，但本脚本也可能从 systemd 之类只有最小环境的地方被拉起
#   （kit 的 restart-dsh-web.sh 就有专门一段处理这件事），那时 NO_PROXY 不在，
#   curl 会把环回请求交给代理，而代理的应答会被误当成 dsh 的应答。
#   显式写死比依赖环境变量稳。
export NO_PROXY="127.0.0.1,localhost${NO_PROXY:+,${NO_PROXY}}"
export no_proxy="$NO_PROXY"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT="${DSH_WSL_KIT:-$(cd "${HERE}/.." && pwd)}"
LIVE="${HOME}/.local/lib/node_modules/@deepseek-ai/dsh"
BIN="${HOME}/.local/bin/dsh"
PATCHER="${HERE}/apply-local-patches.sh"
RESTARTER="${HERE}/restart-dsh-web.sh"
LOGDIR="${HOME}/.dsh/logs"
LOG="${LOGDIR}/revive-$(date +%Y%m%d-%H%M%S).log"

NO_START=0
QUIET=0
for a in "$@"; do
  case "$a" in
    --no-start) NO_START=1 ;;
    --quiet)    QUIET=1 ;;
  esac
done

mkdir -p "$LOGDIR"

# ★ 日志同时落在 WSL 与 Windows 桌面：出问题时人只需要把桌面那份发出来，
#   不必进 WSL、不必知道 journalctl 或 /proc 怎么看。
WINLOG=""
WINHOME="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r' || true)"
if [[ -n "$WINHOME" ]]; then
  WINLOG="$(wslpath -u "$WINHOME" 2>/dev/null)/Desktop/dsh-revive-log.txt"
fi
[[ -n "$WINLOG" && -d "$(dirname "$WINLOG")" ]] || WINLOG=""

say() {
  local line="$*"
  printf '%s\n' "$line"
  printf '%s\n' "$line" >> "$LOG"
  [[ -n "$WINLOG" ]] && printf '%s\n' "$line" >> "$WINLOG"
}
step() { say ""; say "──── $* ────"; }
ok()   { say "  OK    $*"; }
warn() { say "  WARN  $*"; }
bad()  { say "  FAIL  $*"; bad_count=$((bad_count + 1)); }

bad_count=0
fixed_count=0

# 复用 kit 的存活判定：401 是【活着】的信号（裸开设计如此）
# shellcheck source=dsh-web-alive.inc.sh
if [[ -f "${HERE}/dsh-web-alive.inc.sh" ]]; then
  # shellcheck disable=SC1091
  source "${HERE}/dsh-web-alive.inc.sh"
else
  dsh_web_port()   { echo "${DSH_WEB_PORT:-3080}"; }
  dsh_relay_port() { echo "${DSH_RELAY_PORT:-3081}"; }
  dsh_http_up()    { case "${1:-}" in 200|301|302|303|401) return 0 ;; *) return 1 ;; esac; }
fi

[[ -n "$WINLOG" ]] && : > "$WINLOG"
step "dsh 急救 $(date '+%Y-%m-%d %H:%M:%S')"
say "  日志    ${LOG}"
[[ -n "$WINLOG" ]] && say "  桌面副本 ${WINLOG}"

# ── 1 包是否完整 ──────────────────────────────────────────────────────────
# npm 装的包若缺 lib/bin.js，dsh 无论如何起不来，且这不是本脚本能补的（要重装）。
step "1/6 检查包完整性"
if [[ -f "${LIVE}/package.json" && -f "${LIVE}/lib/bin.js" ]]; then
  ok "包完整（$(node -p "require('${LIVE}/package.json').version" 2>/dev/null || echo '版本未知')）"
else
  bad "包不完整：$([[ -f "${LIVE}/package.json" ]] || echo '缺 package.json ')$([[ -f "${LIVE}/lib/bin.js" ]] || echo '缺 lib/bin.js')"
  warn "这一项要重装才能修，本脚本不联网重装（这一步只能靠重装）"
  warn "请先看 ~/.dsh/dsh-upgrade-backup-* 里有没有完整副本可以拷回"
fi

# ── 2 软链 ────────────────────────────────────────────────────────────────
# npm 中断会只留下改名中的临时名，PATH 上的 dsh 就没了。
step "2/6 检查 ~/.local/bin/dsh 软链"
if [[ -e "$BIN" && -x "$BIN" ]]; then
  ok "软链在（$(readlink "$BIN" 2>/dev/null || echo '实体文件')）"
else
  warn "软链缺失或不可执行 —— 重建"
  mkdir -p "$(dirname "$BIN")"
  rm -f "${HOME}/.local/bin/.dsh-"* 2>/dev/null || true
  if ln -sfn "../lib/node_modules/@deepseek-ai/dsh/lib/bin.js" "$BIN" 2>/dev/null; then
    chmod +x "${LIVE}/lib/bin.js" 2>/dev/null || true
    hash -r 2>/dev/null || true
    ok "已重建 → $(readlink "$BIN")"
    fixed_count=$((fixed_count + 1))
  else
    bad "重建失败（检查 ${HOME}/.local/bin 是否可写）"
  fi
fi
command -v dsh >/dev/null 2>&1 && ok "dsh --version = $(dsh --version 2>/dev/null | head -1)" || warn "dsh 仍不在 PATH 上"

# ── 3 依赖树完整性（最隐蔽的一处） ────────────────────────────────────────
# 判据：node_modules 下每个顶层包都要有能解析的 package.json。
# 残缺时【从最新备份补这个包】，不联网重装。
step "3/6 检查依赖树完整性"
BROKEN="$(node -e '
const fs=require("fs"),p=process.argv[1];
let bad=[];
if(!fs.existsSync(p)){process.exit(0);}
const names=[];
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
console.log(bad.join("\n"));
' "${LIVE}/node_modules" 2>/dev/null || true)"

if [[ -z "${BROKEN//[[:space:]]/}" ]]; then
  ok "依赖树完整（顶层包都有可解析的 package.json）"
else
  n_broken="$(printf '%s\n' "$BROKEN" | grep -c . || true)"
  warn "发现 ${n_broken} 个残缺包："
  printf '%s\n' "$BROKEN" | sed 's/^/          /' | tee -a "$LOG" >/dev/null
  printf '%s\n' "$BROKEN" | while read -r line; do say "          $line"; done

  # 找最新的、确实含有该包的备份
  BK=""
  for cand in $(ls -dt "${HOME}"/.dsh/dsh-upgrade-backup-*/dsh-before 2>/dev/null); do
    [[ -d "${cand}/node_modules" ]] || continue
    BK="$cand"; break
  done
  if [[ -z "$BK" ]]; then
    bad "没有可用备份，无法自动补；需要联网重装（先看 docs/MAINTENANCE.zh.md §6）"
  else
    say "  用备份 ${BK}"
    while read -r pkg; do
      [[ -n "$pkg" ]] || continue
      src="${BK}/node_modules/${pkg}"
      dst="${LIVE}/node_modules/${pkg}"
      if [[ -d "$src" && -f "${src}/package.json" ]]; then
        mkdir -p "$dst"
        if cp -a "${src}/." "$dst/" 2>/dev/null; then
          ok "  从备份补回 ${pkg}（$(find "$dst" -type f 2>/dev/null | wc -l) 个文件）"
          fixed_count=$((fixed_count + 1))
        else
          bad "  补 ${pkg} 失败"
        fi
      else
        bad "  备份里也没有完整的 ${pkg}"
      fi
    done <<< "$BROKEN"
    # 复查
    still="$(node -e '
const fs=require("fs"),p=process.argv[1];
let bad=[];
const names=[];
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
console.log(bad.length);
' "${LIVE}/node_modules" 2>/dev/null || echo '?')"
    if [[ "$still" == "0" ]]; then ok "复查：依赖树已完整 ✓"; else bad "复查：仍有 ${still} 个残缺包"; fi
  fi
fi

# ── 4 本地定制 ────────────────────────────────────────────────────────────
# 升级会覆盖 node_modules，两项定制（undici 7.18.2 / cordis 补丁）必须重打。
step "4/6 检查本地定制（undici 7.18.2 / cordis 补丁）"
if [[ -x "$PATCHER" || -f "$PATCHER" ]]; then
  if bash "$PATCHER" --check >/tmp/revive-patchcheck.txt 2>&1; then
    ok "两项定制都在"
  else
    warn "有定制没生效 —— 重打"
    if bash "$PATCHER" >>"$LOG" 2>&1 && bash "$PATCHER" --check >>"$LOG" 2>&1; then
      ok "已重打并验证通过"
      fixed_count=$((fixed_count + 1))
    else
      bad "重打失败，详见 ${LOG}"
      tail -6 /tmp/revive-patchcheck.txt | sed 's/^/          /' | while read -r l; do say "$l"; done
    fi
  fi
else
  warn "找不到 apply-local-patches.sh，跳过"
fi

# ── 5 起服务（等端口真的应答，而不是盲 sleep） ────────────────────────────
WEB="$(dsh_web_port)"; RELAY="$(dsh_relay_port)"
step "5/6 起 dsh web :${WEB} + 中继 :${RELAY}"
if [[ "$NO_START" == "1" ]]; then
  say "  （--no-start：跳过，不动正在跑的服务）"
else
  if [[ -f "$RESTARTER" ]]; then
    bash "$RESTARTER" >>"$LOG" 2>&1 || warn "restart-dsh-web.sh 返回非 0（继续看端口）"
  else
    warn "找不到 restart-dsh-web.sh"
  fi
  up=0
  for i in $(seq 1 40); do      # 最多约 80 秒
    code="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 3 "http://127.0.0.1:${WEB}/" 2>/dev/null || echo 000)"
    if dsh_http_up "$code"; then up=1; break; fi
    sleep 2
  done
  if [[ "$up" == "1" ]]; then
    ok "dsh web 活着（:${WEB} → ${code}；裸开 401 是设计如此）"
  else
    bad "dsh web 在 80 秒内没有应答 —— 看启动日志："
    newest="$(ls -t "${HOME}/.dsh/logs"/startup-*.log 2>/dev/null | head -1 || true)"
    if [[ -n "$newest" ]]; then
      say "          最新启动日志 ${newest}"
      grep -icE 'failed to import|MODULE_NOT_FOUND' "$newest" 2>/dev/null | sed 's/^/          其中 import 失败行数: /' | while read -r l; do say "$l"; done
    fi
  fi
fi

# ── 6 结果 ────────────────────────────────────────────────────────────────
step "6/6 结果"
for p in "$WEB" "$RELAY"; do
  code="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 3 "http://127.0.0.1:${p}/" 2>/dev/null || echo 000)"
  if dsh_http_up "$code"; then ok "端口 :${p} 应答 ${code}"; else bad "端口 :${p} 无应答（${code}）"; fi
done

URL_FILE="${DSH_UI_URL_FILE:-/tmp/dsh-ui-url}"
URL="$(cat "$URL_FILE" 2>/dev/null | tr -d '\r\n' || true)"
if [[ "$URL" == *token=* ]]; then
  say ""
  say "  打开这个地址（已在剪贴板就绪时桌面按钮会替你打开）："
  say "    ${URL}"
else
  warn "还没有带 token 的地址（${URL_FILE} 为空）—— 服务刚起来时再跑一次本脚本"
fi

say ""
if [[ "$bad_count" == "0" ]]; then
  say "════ 结论：可用（自动修好 ${fixed_count} 处）════"
  exit 0
else
  say "════ 结论：有 ${bad_count} 处没修好（自动修好 ${fixed_count} 处）════"
  say "把桌面上的 dsh-revive-log.txt 发出来，就能定位"
  exit 1
fi
