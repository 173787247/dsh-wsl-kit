#!/usr/bin/env node
// Copy dsh-wsl-common/lib into every dsh-wsl- plugin lib folder that already has those files.
import { cpSync, existsSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const kitDir = dirname(fileURLToPath(import.meta.url));
const root = join(kitDir, "..", "..");
const commonLib = join(root, "dsh-wsl-common", "lib");
const sources = ["wsl-host.js", "wsl.js"];
let copied = 0;

for (const name of readdirSync(root)) {
  if (!name.startsWith("dsh-wsl-") || name === "dsh-wsl-common" || name === "dsh-wsl-kit") continue;
  const libDir = join(root, name, "lib");
  if (!existsSync(libDir)) continue;
  for (const file of sources) {
    const src = join(commonLib, file);
    const dest = join(libDir, file);
    if (!existsSync(src) || !existsSync(dest)) continue;
    cpSync(src, dest);
    copied += 1;
    console.log(`${name}/lib/${file}`);
  }
}

console.log(`Synced ${copied} file(s) from dsh-wsl-common.`);
