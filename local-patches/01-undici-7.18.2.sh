#!/usr/bin/env bash
# dsh 内嵌的 undici 8.11.0 → 7.18.2
#
# 为什么：Node 24.13 内置的 fetch 来自 undici 7.18.2。dsh-http-proxy 把 undici 8.11.0
# 的 ProxyAgent 装成【进程全局 dispatcher】，跨大版本时 Node 内置 fetch 拿到的
# Response.headers 是空的 → content-encoding 丢失 → brotli 响应体不解压 →
# web_search 的 JSON.parse 拿到二进制字节流而失败。
#
# 聊天（SSE 流）碰巧不依赖响应头，所以只有 web_search 暴露出来。
#
# 来源：Cursor 于 2026-09-26 诊断并修复，记录在 ~/GO/dsh-websearch-修复记录.md
# 本脚本是那份修复的幂等版本 —— 每次升级 dsh 后重跑。
set -euo pipefail
DSH="${DSH:-$HOME/.local/lib/node_modules/@deepseek-ai/dsh}"
TARBALL="${TARBALL:-$HOME/GO/vendor/undici-7.18.2.tgz}"

cur=$(node -e "console.log(require('$DSH/node_modules/undici/package.json').version)" 2>/dev/null || echo missing)
echo "  当前 undici: $cur"
if [ "$cur" = "7.18.2" ]; then echo "  已是最新，跳过"; exit 0; fi
[ -f "$TARBALL" ] || { echo "  ★ 找不到 tarball: $TARBALL"; exit 1; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
tar -xzf "$TARBALL" -C "$work"
[ -d "$DSH/node_modules/undici" ] && mv "$DSH/node_modules/undici" "$DSH/node_modules/undici.bak-$cur"
cp -r "$work/package" "$DSH/node_modules/undici"
echo "  装完: $(node -e "console.log(require('$DSH/node_modules/undici/package.json').version)")"
