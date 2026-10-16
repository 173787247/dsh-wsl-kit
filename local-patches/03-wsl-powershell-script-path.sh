#!/usr/bin/env bash
# dsh-native-command: 交给 powershell.exe 的 .ps1 路径必须显式翻成 Windows 路径
#
# ★ 为什么
#   windowsFileApplications 把 PowerShell 脚本写进 Linux 临时目录，再把该路径作为
#   `-File` 的参数交给 powershell.exe。从 Windows 挂载点（/mnt/<盘>/…）启动的进程
#   里，Windows 子进程会把这个前导斜杠的路径解析成【它自己工作目录所在盘符】下的
#   路径，于是脚本根本没被执行：powershell 只把启动横幅写进 stdout 并以 0 退出，
#   调用方 JSON.parse(stdout) 便抛异常。文件卡片的「用应用打开」下拉因此永远显示
#   "Could not load applications" —— 列应用和真正打开走的是同一个函数，一起坏。
#
#   `wslpath -w` 把脚本路径翻成 \\wsl.localhost\<发行版>\… 再交给 -File 就好了。
#   用它而不是自己拼 UNC，是因为它知道该用 wsl$ 还是 wsl.localhost。
#   非 WSL（process.platform === "win32"）或翻不动时原样返回，行为与打补丁前一致。
#
# ★ 两层防护
#   scripts/restart-dsh-web.sh 里的 `cd "$HOME"` 保证宿主 cwd 不落在 /mnt 上；
#   本补丁保证即使 cwd 落在 /mnt 上，PowerShell 也仍能跑起来。
set -euo pipefail
DSH="${DSH:-$HOME/.local/lib/node_modules/@deepseek-ai/dsh}"
TARGET="$DSH/node_modules/@deepseek-ai/dsh-native-command/lib/index.js"
[ -f "$TARGET" ] || { echo "  ★ 找不到 $TARGET"; exit 1; }

node - "$TARGET" <<'JS'
const fs = require("node:fs");

const target = process.argv[2];
const source = fs.readFileSync(target, "utf8");
const MARKER = "async function windowsScriptPath(";

if (source.includes(MARKER)) {
  console.log("  已打过，跳过");
} else {
  const HELPER = `/**
* Make a WSL script path readable by the Windows PowerShell that must run it.
* A Windows child resolves a leading-slash argument against the drive root of its
* own working directory, so a Linux temp path only works while the caller's cwd
* is on the distro filesystem. \`wslpath -w\` names the file unambiguously.
* @param path - absolute Host path of the generated script.
* @param signal - caller cancellation.
* @param run - native command runner.
* @returns the Windows path, or the input path when it cannot be translated.
*/
async function windowsScriptPath(path, signal, run) {
\tif (process.platform === "win32") return path;
\ttry {
\t\tconst translated = await run("wslpath", ["-w", path], signal, "hidden");
\t\tconst windowsPath = translated.stdout.replace(/[\\r\\n]+$/, "");
\t\tif (windowsPath !== "") return windowsPath;
\t} catch (error) {
\t\tif (signal.aborted) throw error;
\t}
\treturn path;
}
async function windowsFileApplications(`;

  const CALL = '\t\treturn (await run("powershell.exe", [';
  const FILE_ARG = '\t\t\t"-File",\n\t\t\tscriptPath\n';

  for (const [name, anchor] of [["windowsFileApplications", "async function windowsFileApplications("], ["powershell 调用", CALL], ["-File 参数", FILE_ARG]]) {
    const hits = source.split(anchor).length - 1;
    if (hits !== 1) {
      console.log(`  ★ 锚点「${name}」命中 ${hits} 次（应为 1），文件已变，放弃`);
      process.exit(1);
    }
  }

  const patched = source
    .replace("async function windowsFileApplications(", HELPER)
    .replace(CALL, '\t\tconst launchPath = await windowsScriptPath(scriptPath, signal, run);\n' + CALL)
    .replace(FILE_ARG, '\t\t\t"-File",\n\t\t\tlaunchPath\n');

  const backup = `${target}.bak-before-wsl-scriptpath`;
  if (!fs.existsSync(backup)) fs.copyFileSync(target, backup);
  fs.writeFileSync(target, patched);
  console.log(`  已打补丁（原件备份在 ${backup.split("/").pop()}）`);
}
JS

# ── 验证 1：模块仍能加载，导出还在 ─────────────────────────────────────────
node -e "
import(require('node:url').pathToFileURL(process.argv[1]).href).then((m) => {
  if (typeof m.nativeFileApplications !== 'function') throw new Error('nativeFileApplications 导出不见了');
  console.log('  ✓ 模块可加载，导出正常');
}, (error) => { console.log('  ★ 加载失败: ' + error.message); process.exit(1); });
" "$TARGET"

# ── 验证 2：注入假 runner，看 -File 拿到的是不是 Windows 路径 ──────────────
node - "$TARGET" <<'JS'
const { pathToFileURL } = require("node:url");
const target = process.argv[2];

(async () => {
  const module_ = await import(pathToFileURL(target).href);
  const calls = [];
  const run = async (command, args) => {
    calls.push([command, ...args]);
    if (command === "wslpath") {
      return { stdout: "\\\\wsl.localhost\\Ubuntu\\tmp\\dsh-native-command-x\\associations.ps1\n", stderr: "" };
    }
    return { stdout: JSON.stringify([{ id: "C:\\app.exe", name: "Probe App", default: true, icon: null }]), stderr: "" };
  };
  const apps = await module_.nativeFileApplications("/tmp/example.docx", new AbortController().signal, {
    platform: "linux",
    env: { WSL_DISTRO_NAME: "Ubuntu" },
    run
  });
  const powershell = calls.find((call) => call[0] === "powershell.exe");
  const fileArgument = powershell[powershell.length - 1];
  const ok = apps.length === 1 && fileArgument.startsWith("\\\\wsl.localhost\\");
  console.log(ok
    ? `  ✓ -File 收到 Windows 路径: ${fileArgument}`
    : `  ★ -File 仍收到 Linux 路径: ${fileArgument}`);
  process.exit(ok ? 0 : 1);
})().catch((error) => { console.log("  ★ " + error.message); process.exit(1); });
JS
