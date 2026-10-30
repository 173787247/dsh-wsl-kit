#!/usr/bin/env bash
# apply-local-patches.sh —— 把我们对 dsh 的本地定制重新应用一遍
#
# ★ 为什么需要它
#   `npm install -g` 升级 dsh 会覆盖整个 node_modules，我们改过的东西全没了。
#   每次升级都「重头再来」不是进化，是原地打转。
#   所以把定制做成幂等脚本，升级后一条命令重打，并【逐条验证】。
#
# ★ 幂等：跑两次和跑一次结果相同。
# ★ 逐条验证：每项都有 verify，验不过就报错 —— 而不是"应该打上了"。
# ★ 可隔离：认 DSH 环境变量，所以能在演练目录里跑，不碰线上。
#
# 用法：
#   bash apply-local-patches.sh                      # 全部重打（线上）
#   bash apply-local-patches.sh --check              # 只检查，不改
#   DSH=/tmp/rehearsal/dsh bash apply-local-patches.sh   # 在隔离目录演练
set -uo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHDIR="$(cd "$HERE/../local-patches" && pwd)"
DSH="${DSH:-$HOME/.local/lib/node_modules/@deepseek-ai/dsh}"
export DSH

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# ── 两项共用的验证器：读 $DSH，不写死路径 ────────────────────────────────
read -r -d '' VERIFY_JS <<'JS' || true
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const DSH = process.env.DSH;
const checks = [
  // 2026-10-18: 不再钉死 7.18.2。判据改成【与 Node 内置版本一致】——
  //   跨大版本的 dispatcher 才是不兼容的根因；同版本就不需要移花接木。
  //   Node 26.12.0 内置 8.11.2 = dsh rc.2 自带 8.11.2，天然匹配。
  { name: `undici 与 Node 内置一致 (${process.versions.undici})`,
    fn: () => require(path.join(DSH, 'node_modules/undici/package.json')).version === process.versions.undici },
  { name: 'cordis 补丁',
    fn: () => {
      const src = fs.readFileSync(path.join(DSH, 'node_modules/@deepseek-ai/cordis/lib/index.js'), 'utf8');
      // 行为标记而不是 bundle 的 md5：cordis 4.0.5 换了 bundle，md5 会随版本变。
      return src.includes('unshift(value)') && src.includes('[Circular]')
        && src.includes('next() called multiple times');
    } },
  { name: 'loader 补丁',
    fn: () => {
      const src = fs.readFileSync(path.join(DSH, 'node_modules/@deepseek-ai/cordis-plugin-loader/lib/index.js'), 'utf8');
      return src.includes('trackDetached') && src.includes('config => this.update(config)')
        && src.includes('if (this.fiber?.uid) return');
    } },
  { name: 'native-command WSL 脚本路径',
    fn: () => {
      const src = fs.readFileSync(path.join(DSH, 'node_modules/@deepseek-ai/dsh-native-command/lib/index.js'), 'utf8');
      return src.includes('async function windowsScriptPath(') && src.includes('const launchPath = await windowsScriptPath(');
    } },
];
let bad = 0;
for (const c of checks) {
  let ok = false;
  try { ok = c.fn(); } catch (e) { ok = false; }
  console.log(`     ${ok ? '✓' : '★'} ${c.name} ${ok ? '通过' : '未生效'}`);
  if (!ok) bad++;
}
process.exit(bad === 0 ? 0 : 1);
JS

PATCHES=(
  "01-undici-7.18.2.sh|dsh 内嵌 undici → 7.18.2（web_search 修复）"
  "02-cordis-backports.sh|三个 cordis 补丁（进程不再被未捕获拒绝打死）"
  "03-wsl-powershell-script-path.sh|powershell -File 的脚本路径翻成 Windows 路径（文件卡片「用应用打开」）"
)

cd "${HOME}" || true   # ★ 同上

echo "════ 本地定制 ════"
echo "  DSH    $DSH"
echo "  版本   $(node -e "console.log(require('$DSH/package.json').version)" 2>/dev/null || echo '?')"
[ "$CHECK_ONLY" = 1 ] && echo "  ★ --check：只检查，不改"
[ "$DSH" != "$HOME/.local/lib/node_modules/@deepseek-ai/dsh" ] && echo "  ★ 隔离模式（不碰线上）"
echo

for entry in "${PATCHES[@]}"; do
  IFS='|' read -r script desc <<< "$entry"
  printf '  ── %s\n     %s\n' "$script" "$desc"
  if [ "$CHECK_ONLY" = 0 ]; then
    out=$(bash "$PATCHDIR/$script" 2>&1); rc=$?
    echo "$out" | sed 's/^/     /'
    if [ "$rc" -ne 0 ]; then echo "     ★ 脚本退出码 $rc"; fi
  fi
  echo
done

echo "════ 逐条验证 ════"
echo "$VERIFY_JS" | node
rc=$?
echo
if [ "$rc" -ne 0 ]; then
  echo "★ 有定制没生效。修好之前，升级不算完成。"
  exit 1
fi
echo "全部本地定制都已生效。"
echo
echo "  生效需要重启 dsh（模块在进程启动时载入）："
echo "    bash $HERE/restart-dsh-web-detached.sh"
