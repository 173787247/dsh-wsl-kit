#!/usr/bin/env python3
"""把 README 兼容性表里声称的插件版本，同步成 package.json 的实际版本。

只改「| **插件** | `name` **x.y.z** |」和英文对应的那一行 —— 不动别的版本号。
DRY=1 时只报告。
"""
import json, os, pathlib, re, sys

ROOT = pathlib.Path(os.environ.get('DSH_FIX_ROOT',
        '/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment'))
DRY = os.environ.get('DSH_FIX_DRY') == '1'

# 匹配 | **插件** | `name` **1.2.3** |   （中英两种标签）
ROW = re.compile(
    r'(?P<pre>\|\s*\*\*(?:插件|Plugin)\*\*\s*\|\s*`(?P<name>[a-z0-9-]+)`\s*\*\*)'
    r'(?P<ver>[0-9]+\.[0-9]+\.[0-9]+)'
    r'(?P<post>\*\*\s*\|)')

changed = []
for d in sorted(ROOT.iterdir()):
    if not d.is_dir() or not d.name.startswith('dsh-'):
        continue
    pj = d / 'package.json'
    if not pj.is_file():
        continue
    try:
        actual = json.loads(pj.read_text(encoding='utf-8')).get('version')
    except Exception:
        continue
    if not actual:
        continue
    for fname in ('README.md', 'README.zh.md', 'README.en.md'):
        p = d / fname
        if not p.is_file():
            continue
        text = p.read_text(encoding='utf-8')
        hits = list(ROW.finditer(text))
        if not hits:
            continue
        new = text
        for m in reversed(hits):
            if m.group('ver') != actual:
                new = new[:m.start('ver')] + actual + new[m.end('ver'):]
                changed.append((d.name, fname, m.group('name'), m.group('ver'), actual))
        if new != text and not DRY:
            p.write_text(new, encoding='utf-8')

print(f'  {"(DRY) " if DRY else ""}改了 {len(changed)} 处')
for r, f, n, old, new in changed:
    print(f'     {r:26} {f:14} {n:24} {old} -> {new}')
