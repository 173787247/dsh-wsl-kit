#!/usr/bin/env bash
# boot.sh —— 一键把 dsh-wsl-kit 装到这台 WSL 上
#
# ★ 它做什么（五步，每步都断言，失败指名）
#   1 查环境    WSL · dsh · 端口 · .wslconfig · 代理 · Windows 侧 Chrome
#   2 装插件集  install.sh（KIT_SET）
#   3 装本地定制 undici + cordis 补丁（apply-local-patches.sh）
#   4 装 Windows 常驻者 dsh-ui-watcher（浏览器在重启后自己回来靠它）
#   5 自检      起 dsh → 验端口 → 验 token → 验 watcher 心跳 → 报告
#
# ★ 为什么每步都断言
#   这一套里最容易出的错是【静默失败】：命令退出码 0 但什么都没做。
#   例如从 systemd 单元里 Start-Process 开浏览器 —— 退出码 0，浏览器不出现。
#   所以每一步之后都验一次结果，而不是信任退出码。
#
# 用法
#   bash boot.sh                 # 全跑
#   bash boot.sh --check         # 只查环境与现状，不改任何东西
#   KIT_SET=daily bash boot.sh   # 装小一点的集
#
# 生成者: dsh-wsl-kit 维护者

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT="$(cd "$HERE/.." && pwd)"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
KIT_SET="${KIT_SET:-full}"

ok=0; bad=0
say()  { printf '  %s\n' "$*"; }
head_() { printf '\n════ %s ════\n' "$*"; }
pass() { printf '  ✓ %s\n' "$*"; ok=$((ok+1)); }
fail() { printf '  ★ %s\n' "$*"; bad=$((bad+1)); }

# ── 1 查环境 ───────────────────────────────────────────────────────────────
head_ "1/5 查环境"
grep -qi microsoft /proc/version 2>/dev/null && pass "在 WSL 里" || fail "不在 WSL 里（这套是给 WSL 用的）"

if command -v dsh >/dev/null 2>&1; then
  pass "dsh $(dsh --version 2>/dev/null || echo '?')"
else
  fail "没有 dsh —— 先装它：npm install -g --prefix ~/.local @deepseek-ai/dsh@next"
fi

for p in 3080 3081; do
  if ss -ltn 2>/dev/null | grep -q ":${p} "; then
    say "· 端口 $p 已被占用（可能 dsh 正在跑，正常）"
  else
    say "· 端口 $p 空着"
  fi
done

if grep -qi 'networkingMode *= *mirrored' /mnt/c/Users/*/.wslconfig 2>/dev/null; then
  pass "WSL 网络是 mirrored（Windows 可直连 3080）"
else
  say "· 不是 mirrored —— Windows 需经 3081 relay，脚本已按此设计"
fi

if [ -n "${HTTP_PROXY:-}" ] || [ -f ~/.dsh/settings.yaml ]; then
  pass "代理/配置已设（HTTP_PROXY=${HTTP_PROXY:-未设}）"
else
  say "· 没看到代理设置 —— 若 API 调用失败，见 docs/TROUBLESHOOTING.zh.md"
fi

PS1_UNC="\\\\wsl.localhost\\$(grep -oP '(?<=^NAME=").*(?="$)' /etc/os-release 2>/dev/null || echo Ubuntu-24.04 2>/dev/null)"
HDIR="${HERE}/windows"
for f in dsh-wsl-env.ps1 dsh-ui-watcher.ps1 install-watcher.ps1; do
  [ -f "$HDIR/$f" ] && pass "$f 在" || fail "$f 缺"
done

[ "$CHECK_ONLY" = 1 ] && { head_ "只查不改（--check）· $ok 通过 · $bad 失败"; exit $([ "$bad" -eq 0 ] && echo 0 || echo 1); }

# ── 2 装插件集 ─────────────────────────────────────────────────────────────
head_ "2/5 装插件集（KIT_SET=$KIT_SET）"
if [ -x "$KIT/install.sh" ]; then
  if KIT_SET="$KIT_SET" bash "$KIT/install.sh" 2>&1 | tail -6 | sed 's/^/  · /'; then
    n=$(ls ~/.dsh/profiles/web/node_modules 2>/dev/null | grep -c '^dsh-wsl-' || echo 0)
    [ "$n" -gt 0 ] && pass "已装 $n 个 dsh-wsl-* 插件" || fail "装完但看不到插件"
  else
    fail "install.sh 失败"
  fi
else
  fail "找不到 $KIT/install.sh"
fi

# ── 3 装本地定制 ───────────────────────────────────────────────────────────
head_ "3/5 装本地定制（undici + cordis 补丁）"
if [ -x "$KIT/scripts/apply-local-patches.sh" ]; then
  if bash "$KIT/scripts/apply-local-patches.sh" 2>&1 | tail -8 | sed 's/^/  · /'; then
    pass "全部本地定制已生效"
  else
    fail "有定制没打上 —— 修好之前不算装完"
  fi
else
  fail "找不到 apply-local-patches.sh"
fi

# ── 4 装 Windows 常驻者 ────────────────────────────────────────────────────
head_ "4/5 装 Windows 常驻者（浏览器自己回来靠它）"
export PATH="$PATH:/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0:/mnt/c/WINDOWS/system32"
if command -v powershell.exe >/dev/null 2>&1; then
  distro=$(grep -oP '(?<=^NAME=").*(?="$)' /etc/os-release 2>/dev/null || echo Ubuntu-24.04)
  unc="\\\\wsl.localhost\\${distro}\\$(echo "$HDIR" | sed 's|^/||; s|/|\\\\|g')\\install-watcher.ps1"
  say "调用 $unc"
  if timeout 90 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$unc" 2>&1 | sed 's/^/  · /'; then
    pass "watcher 已装"
  else
    fail "install-watcher.ps1 失败 —— 浏览器重启后不会自己回来（点桌面仍可）"
  fi
else
  fail "找不到 powershell.exe —— 无法装常驻者"
fi

# ── 5 自检 ─────────────────────────────────────────────────────────────────
head_ "5/5 自检"
sleep 3
for p in 3080 3081; do
  code=$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 3 "http://127.0.0.1:${p}/" 2>/dev/null)
  [ "$code" = "401" ] && pass "端口 $p 在听（401 = 要 token，正常）" || say "· 端口 $p → ${code:-连不上}"
done
if [ -s /tmp/dsh-ui-url ]; then
  pass "token URL 已写：$(sed -E 's/(token=.{8}).*/\1…/' /tmp/dsh-ui-url)"
else
  fail "/tmp/dsh-ui-url 空 —— 重启一次 dsh：bash $KIT/scripts/restart-dsh-web.sh"
fi
if command -v powershell.exe >/dev/null 2>&1; then
  log_win=$(powershell.exe -NoProfile -Command '(Join-Path $env:USERPROFILE "dsh-ui-watcher.log")' 2>/dev/null | tr -d '\r' | tail -1)
  if [ -n "$log_win" ]; then
    tail_win=$(powershell.exe -NoProfile -Command "Get-Content '$log_win' -Tail 1" 2>/dev/null | tr -d '\r' | tail -1)
    case "$tail_win" in
      *alive*) pass "watcher 心跳正常：$tail_win" ;;
      *)       fail "watcher 日志最后一行不像心跳：$tail_win" ;;
    esac
  fi
fi

head_ "结果：$ok 通过 · $bad 失败"
[ "$bad" -eq 0 ] && echo "  装好了。" || echo "  ★ 有 $bad 项没过 —— 上面每条的 ★ 就是要修的。"
exit $([ "$bad" -eq 0 ] && echo 0 || echo 1)
