#!/usr/bin/env node
import { execute, format } from "/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-wsl-tray/lib/tray.js";

const result = await execute({ action: "install_tray", url: "http://127.0.0.1:3080" });
console.log(format(result));
