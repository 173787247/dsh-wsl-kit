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
# ★ 可被 DSH_UPGRADE_DETACHED 覆盖 —— 这样"退出兜底"能在【不真重启】的情况下被验到。
DETACHED="${DSH_UPGRADE_DETACHED:-$HERE/restart-dsh-web-detached.sh}"

DRY=0
SKIP_NOTES=0
for _a in "$@"; do
  case "$_a" in
    --dry)        DRY=1 ;;
    --skip-notes) SKIP_NOTES=1 ;;
  esac
done
set -- $(printf '%s\n' "$@" | grep -v -e '^--dry$' -e '^--skip-notes$')
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
# ── ★★★ 退出兜底：无论脚本因为什么退出，都不能把 dsh 留在停止状态 ──────────
#
# ★ 为什么要有它（2026-10-16 实测）
#   脚本设了 `set -uo pipefail`。`-u` 在【未定义变量】时直接终止进程 ——
#   而那一晚就真的发生了：4b 里 `$prof` 打成了 `$prof`（应为 `$_prof`），
#   进程当场结束 ⇒ 5/6「起回来」永远没跑 ⇒ **dsh 被留在停止状态**，
#   只能由人手工跑 restart-dsh-web.sh 才回来。
#
#   已经有三条 exit 路径会主动把 dsh 起回来（安装失败 / 依赖树坏 / 正常结束），
#   但它们只覆盖【预料到的】失败。这个 trap 覆盖【任何原因的】结束 ——
#   包括未定义变量、被 kill、以及我没预料到的那些。
#
# ★ 它为什么不会和别的东西抢
#   先探 3080：应答（401 也算活）⇒ 直接返回，什么都不做。
#   而这与 revive-dsh.sh 里那个守卫是同一个判据 ⇒ 两层都不会起第二份。
_ensure_up() {
  local _c
  # ★ 不要 `|| echo 000`：curl 连不上时自己就打 000，再接一个就成了 "000000"。
  _c="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --max-time 5 \
        "http://127.0.0.1:${DSH_WEB_PORT:-3080}/" 2>/dev/null)"
  _c="${_c:-000}"
  case "$_c" in
    200|301|302|303|401) return 0 ;;
  esac
  printf '%s  退出兜底: :%s ⇒ %s ⇒ 起回来\n' \
    "$(date '+%H:%M:%S')" "${DSH_WEB_PORT:-3080}" "${_c:-000}" >> /tmp/dsh-upgrade.log
  bash "$DETACHED" >> /tmp/dsh-upgrade.log 2>&1 || true
}
trap _ensure_up EXIT

if [ "$DRY" = 1 ]; then log "  ★ --dry：到此为止"; exit 0; fi

# ── 0 ★★★ 先读目标版本的 release notes（2026-10-16 加） ────────────────────
#
# ★ 为什么必须在【装任何东西之前】
#   dsh 0.2.1-alpha.4 把插件兼容性改成"按插件声明的 engines.dsh 判定"——
#   而这一条只写在 release notes 的「其他变更 / Other changes」一节里。
#   升级前没人读它 ⇒ 升完插件被【整行禁用】：
#       disabling profile plugin row "<id>": Plugin <pkg>@<old> is incompatible …
#   ⇒ 界面照常打开，而那个插件提供的工具与面板【安静地没有】。
#
#   而 release notes 里那一节通常只有一两行，读它的成本是【十秒】。
#
# ★ 读不到就停下（除非显式 --skip-notes）
#   "不知道改了什么就往下装"正是出事的那条路。
log "════ 0/6 读 $TARGET 的 release notes ════"
_dsh_core_log="$(dsh --version >/dev/null 2>&1; echo "${DSH_WEB_LOG:-/tmp/dsh-web.log}")"
_NOTES_BEFORE_COUNT="$(grep -c 'disabling profile plugin row' "$_dsh_core_log" 2>/dev/null || echo 0)"
_NOTES_BEFORE_SIZE="$(stat -c%s "$_dsh_core_log" 2>/dev/null || echo 0)"
echo "$_NOTES_BEFORE_COUNT" > /tmp/dsh-upgrade-notes-before-count
echo "$_NOTES_BEFORE_SIZE"  > /tmp/dsh-upgrade-notes-before-size
log "  基线: 启动日志 $_dsh_core_log · 禁用行 $_NOTES_BEFORE_COUNT 条 · $_NOTES_BEFORE_SIZE 字节"

_notes="$(curl -fsSL --max-time 30 \
  "https://api.github.com/repos/deepseek-ai/deepseek-harness/releases/tags/dsh-v${TARGET}" 2>/dev/null \
  | node -e '
let s=""; process.stdin.on("data",d=>s+=d).on("end",()=>{
  try {
    const b = JSON.parse(s).body || "";
    let at = b.search(/其他变更|Other Changes/);
    if (at < 0) { at = b.search(/新增功能|New Features/); }
    console.log(at < 0 ? "" : b.slice(at, at + 1500));
  } catch (e) { console.log(""); }
});' 2>/dev/null)"
if [ -z "$_notes" ]; then
  log "  ★ 读不到 release notes（网络不通，或这个 tag 没有 release）"
  if [ "$SKIP_NOTES" = "1" ]; then
    log "  --skip-notes ⇒ 继续（日志里记下你跳过了）"
  else
    log "  ⇒ 停下。修好网络再跑，或显式加 --skip-notes 表示「我知道我在不知道改了什么的情况下升级」"
    exit 3
  fi
else
  printf '%s\n' "$_notes" | sed 's/^/  │ /'
fi

# ── 1 备份 ─────────────────────────────────────────────────────────────────
BK="${HOME}/.dsh/dsh-upgrade-backup-$(date +%Y%m%d_%H%M%S)"
log "════ 1/6 备份到 $BK ════"
mkdir -p "$BK"
cp -r "$LIVE" "$BK/dsh-before" 2>/dev/null && log "  ✓ dsh 包"
cp "$HOME/.dsh/profiles/web/cordis.patch.yml" "$BK/" 2>/dev/null && log "  ✓ cordis.patch.yml"
# ★ 2026-10-16: profile 的 package.json 也要备份 —— 4b 会改它（把 @deepseek-ai/* 升到新版本），
#   而原来没有它 ⇒ 4b 一旦失败就【回退不到干净状态】：核心回退了、profile 却已经动过。
for _pf in "$HOME"/.dsh/profiles/*/package.json; do
  [ -f "$_pf" ] || continue
  _pn="$(basename "$(dirname "$_pf")")"
  cp "$_pf" "$BK/profile-${_pn}-package.json" 2>/dev/null && log "  ✓ profile/${_pn}/package.json"
done
unset _pf _pn
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

# ── 3b ★ 依赖树完整性 ────────────────────────────────────────────────────────
# 一次被打断的安装会留下三处伤，这是最隐蔽的一处：依赖树残缺。
# 症状不是起不来，而是【进程照起、端口照答，只在真正用到那条路径时才炸】——
# 2026-10-05 实测：zod 少到 614/840（缺 v4/locales/index.js）就让 dsh web 起来 5 秒后死；
# @smithy/core 少到 495/1109（缺 package.json）则连启动都看不出来，属隐伤。
# 所以这里必须查，而且补不回时要当成失败、走下面的回滚 —— 而不是留给人去翻日志。
log "════ 3b/6 依赖树完整性 ════"
_tree_broken() {
  node -e '
const fs = require("fs"), p = process.argv[1];
let names = [];
for (const d of fs.readdirSync(p)) {
  if (d.startsWith(".")) continue;
  if (d.startsWith("@")) { for (const s of fs.readdirSync(p + "/" + d)) names.push(d + "/" + s); }
  else names.push(d);
}
const bad = [];
for (const n of names) {
  const pj = p + "/" + n + "/package.json";
  if (!fs.existsSync(pj)) { bad.push(n); continue; }
  try { JSON.parse(fs.readFileSync(pj, "utf8")); } catch { bad.push(n); }
}
console.log(bad.join("\n"));
' "$LIVE/node_modules" 2>/dev/null || true
}
BROKEN_TREE="$(_tree_broken)"
if [ -z "${BROKEN_TREE//[[:space:]]/}" ]; then
  log "  ✓ 依赖树完整"
else
  log "  ★ 依赖树残缺 $(printf '%s\n' "$BROKEN_TREE" | grep -c .) 个包 —— 尝试从备份按包补回"
  while read -r pkg; do
    [ -n "$pkg" ] || continue
    src="$BK/dsh-before/node_modules/$pkg"; dst="$LIVE/node_modules/$pkg"
    if [ -d "$src" ] && [ -f "$src/package.json" ]; then
      mkdir -p "$dst"
      if cp -a "$src/." "$dst/" 2>/dev/null; then log "     ✓ 补回 $pkg"; else log "     ✗ 补 $pkg 失败"; fi
    else
      log "     ✗ 备份里也没有完整的 $pkg"
    fi
  done <<< "$BROKEN_TREE"
  STILL_BROKEN="$(_tree_broken)"
  if [ -z "${STILL_BROKEN//[[:space:]]/}" ]; then
    log "  ✓ 补齐后依赖树完整"
  else
    log "  ★ 仍有残缺：$(printf '%s' "$STILL_BROKEN" | tr '\n' ' ') —— 回滚"
    rm -rf "$LIVE"; cp -r "$BK/dsh-before" "$LIVE"
    log "  ✓ 已回滚到 $(dsh --version 2>/dev/null || echo unknown)"
    bash "$DETACHED" >> /tmp/dsh-upgrade.log 2>&1
    exit 1
  fi
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
# ── 4b ★★★ 同步 profile 里钉的 @deepseek-ai/* 插件版本 ────────────────────
#
# ★ 为什么必须单独有这一步（2026-10-16 实测漏掉它，症状是"界面能开，但功能悄悄少了"）
#
#   升级只换 dsh 本体是不够的：profile 的 package.json 里还钉着一批插件版本。
#   本体升了、插件没升 ⇒ 启动时 dsh 会打印
#
#     dsh: disabling profile plugin row "agent-team":
#          Plugin @deepseek-ai/dsh-experimental-agent-team@<旧> is incompatible
#          with dsh <新>: requirements {"@deepseek-ai/dsh-agent":"<旧>", ...}
#
#   并把那一行【整行禁用】⇒ 该插件提供的工具与面板全部消失。
#   ★ 它不是报错，是安静地没有 —— 所以不看启动日志就发现不了。
#
# ★ 怎么升：必须用 dsh 自己的安装器，它走 pnpm。
#     普通 `npm install` 会因为 profile 里的 `link:` / `github:` 依赖直接
#     EUNSUPPORTEDPROTOCOL 失败（实测 2026-10-16）。
#
# ★ 只升"同一条版本轨"的包：本体是 0.2.1-alpha.4 ⇒ 只把 0.2.1-alpha.N 的升成 0.2.1-alpha.4。
#   不在同一轨的（例如 0.1.x 的插件）不碰 —— 它们未必跟本体同版本发布。
#
# ★ 怎么验：重启后启动日志里【不该再有】"disabling profile plugin row"。
log "════ 4b/6 同步 profile 插件版本 ════"
_TRACK="$(printf '%s' "$TARGET" | sed -E 's/\.[0-9]+$//')"     # 0.2.1-alpha.4 -> 0.2.1-alpha
if [ -n "$_TRACK" ] && [ "$_TRACK" != "$TARGET" ]; then
  for _pj in "${HOME}"/.dsh/profiles/*/package.json; do
    [ -f "$_pj" ] || continue
    _prof="$(basename "$(dirname "$_pj")")"
    _stale="$(node -e '
      const fs=require("fs");
      const t=process.argv[1], track=process.argv[2], out=[];
      let d={}; try { d=JSON.parse(fs.readFileSync(process.argv[3],"utf8")); } catch { process.exit(0); }
      for (const [k,v] of Object.entries(d.dependencies||{})) {
        if (!k.startsWith("@deepseek-ai/")) continue;
        if (!/^\d+\.\d+\.\d+-/.test(v)) continue;          // 只处理具体版本号
        if (v === t) continue;
        if (v.startsWith(track + ".")) out.push(k + "@" + t); // 同一条轨才升
      }
      console.log(out.join("\n"));
    ' "$TARGET" "$_TRACK" "$_pj" 2>/dev/null)"
    [ -n "$_stale" ] || continue
    while IFS= read -r _spec; do
      [ -n "$_spec" ] || continue
      log "  ${_prof}: ${_spec}"
      if dsh plugin --profile "$_prof" add "$_spec" >/tmp/dsh-plugin-add-$$.log 2>&1; then
        log "     ✓ 已升"
      else
        log "     ★ 升级失败 —— 见 /tmp/dsh-plugin-add-$$.log（不影响 dsh 本体）"
      fi
    done <<< "$_stale"
  done
  unset _prof _pj _stale _spec
else
  log "  跳过（版本号形如 $_TRACK，无法判断同轨）"
fi
unset _TRACK

# ── 4b 复核 ★ 光"跑过"不算数，要看【结果】
#
#   为什么要复核：2026-10-16 那次 4b 因为一个未定义变量当场中止（set -u），
#   一行都没执行 ⇒ 核心升了、插件没升 ⇒ 启动日志里 32 条 disabling。
#   而当时的脚本对"4b 到底成没成"没有任何判断。
_off="$(node -e '
  const fs=require("fs"), path=require("path");
  const base=process.argv[1], track=process.argv[2];
  let bad=[];
  for (const prof of fs.readdirSync(base)) {
    const pj=path.join(base,prof,"package.json");
    let d; try { d=JSON.parse(fs.readFileSync(pj,"utf8")); } catch { continue; }
    for (const [k,v] of Object.entries(d.dependencies||{})) {
      if (!k.startsWith("@deepseek-ai/")) continue;
      if (!/^\d+\.\d+\.\d+-/.test(v)) continue;
      if (!v.startsWith(track+".")) continue;
      const inst=path.join(base,prof,"node_modules",...k.split("/"),"package.json");
      let iv=null; try { iv=JSON.parse(fs.readFileSync(inst,"utf8")).version; } catch {}
      if (iv !== v) bad.push(prof+": "+k+" 钉"+v+" 装"+(iv||"缺"));
    }
  }
  console.log(bad.join("\n"));
' "$HOME/.dsh/profiles" "${TARGET%.*}" 2>/dev/null || true)"
if [ -n "${_off//[[:space:]]/}" ]; then
  log "  ★★ profile 里仍有没跟上的插件 —— 这次升级【不算完成】"
  printf '%s\n' "$_off" | sed 's/^/     /'
  log "  多半是 4b 没跑成（例如脚本中途中止）。修法："
  log "     bash $0 $TARGET          # 重跑一次（4b 是幂等的）"
  log "  或手工："
  log "     dsh plugin --profile web add <包名>@$TARGET"
  log "  ★ 而【不要】就这么重启 —— 插件没跟上核心时，dsh 会把那些插件整行禁用"
  _UPGRADE_INCOMPLETE=1
else
  log "  ✓ profile 里的插件都跟上了"
fi
unset _off

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
# ── 6b ★★★ 验：新实例的启动日志里【不该有新增的】插件禁用行 ────────────────
#
# ★ 判据（两个方向都能失败）
#   升完重启之后，读【当前那份】启动日志里的 `disabling profile plugin row`：
#     · 日志被截断（变小）⇒ 整份都是本次启动 ⇒ 条数必须是 0
#     · 日志没截断        ⇒ 条数必须【等于】升级前记下的基线
#   任一不满足 ⇒ 这次升级【不算成功】，哪怕 npm 说装好了。
#
#   为什么要有它：那个脚本原来把"装上了 + 补丁打上了"当成成功，
#   而 2026-10-16 那次的坏消息【就印在启动日志第一行】，脚本看都没看。
sleep 6
log "════ 6b/6 验证新实例 ════"
_after_count="$(grep -c 'disabling profile plugin row' "$_dsh_core_log" 2>/dev/null || echo 0)"
_after_size="$(stat -c%s "$_dsh_core_log" 2>/dev/null || echo 0)"
_before_count="$(cat /tmp/dsh-upgrade-notes-before-count 2>/dev/null || echo 0)"
_before_size="$(cat /tmp/dsh-upgrade-notes-before-size  2>/dev/null || echo 0)"
log "  禁用行: 升级前 $_before_count ⇒ 现在 $_after_count   （日志 $_before_size ⇒ $_after_size 字节）"
_upgrade_ok=1
if [ "$_after_size" -lt "$_before_size" ]; then
  [ "$_after_count" -eq 0 ] || _upgrade_ok=0
  log "  日志被截断 ⇒ 整份属于本次启动 ⇒ 条数必须是 0"
else
  [ "$_after_count" -le "$_before_count" ] || _upgrade_ok=0
  log "  日志未截断 ⇒ 条数不该超过基线"
fi
if [ "$_upgrade_ok" = "0" ]; then
  log "  ★★ 有新被禁用的插件行 —— 这次升级【不算成功】"
  grep -a 'disabling profile plugin row' "$_dsh_core_log" 2>/dev/null | tail -4 | sed 's/^/     /'
  log "  多半是 profile 里钉的插件版本没跟上核心（见本脚本 4b 步）"
  log "  回退: rm -rf $LIVE && cp -r $BK/dsh-before $LIVE && bash ${HERE}/restart-dsh-web-detached.sh"
else
  log "  ✓ 没有新被禁用的插件行"
fi

log "════ 6/6 总结 ════"
log "  版本      $(dsh --version 2>/dev/null || echo unknown)"
log "  dsh web   $(pgrep -f 'dsh web .*--port 3080' | head -1 || echo '★ 没起来')"
log "  备份      $BK"
log "  回滚      rm -rf $LIVE && cp -r $BK/dsh-before $LIVE"
log "  日志      /tmp/dsh-upgrade.log"
log "════ 完成 ════"
