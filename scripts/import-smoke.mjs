#!/usr/bin/env node
// 对每个插件仓做纯 import 自检：把它的 lib/*.js 逐个 import 一遍。
// 只测能不能加载，不碰网络、不碰 Windows、不执行工具。
import { readdirSync, existsSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

// 默认扫 Windows 侧的检出根（全套插件在那）
const W = process.argv[2] || process.env.DSH_WSL_ROOT || '/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment';
const repos = readdirSync(W).filter(n => n.startsWith('dsh-')).sort();

let pass = 0, fail = 0, noentry = 0;
const failures = [];

for (const r of repos) {
  const dir = join(W, r);
  if (!existsSync(join(dir, 'package.json'))) continue;
  const lib = join(dir, 'lib');
  if (!existsSync(lib)) { noentry++; continue; }

  const files = readdirSync(lib).filter(f => f.endsWith('.js') && !f.endsWith('.min.js'));
  let bad = null;
  for (const f of files) {
    try {
      await import(pathToFileURL(join(lib, f)).href);
    } catch (e) {
      bad = `${f}: ${(e.message || String(e)).slice(0, 110)}`;
      break;
    }
  }
  if (bad) { fail++; failures.push([r, bad]); }
  else pass++;
}

console.log(`  ✓ 通过 ${pass} 个`);
console.log(`  ★ 失败 ${fail} 个`);
if (noentry) console.log(`  – 无 lib/ ${noentry} 个`);
if (failures.length) {
  console.log('\n  失败明细:');
  for (const [r, m] of failures) console.log(`     ${r}\n        ${m}`);
}
process.exit(fail ? 1 : 0);
