#!/usr/bin/env python3
"""审计全套插件 README 的一致性 —— 可重复，退出码 1 表示有发现。

检五件事：
  1 兼容性表里声称的插件版本 == package.json 的 version
  2 相对链接指向的文件存在
  3 每个 README 有兼容性表（dsh-wsl-common 是库，豁免）
  4 没有残留的 npm 标签（@alpha —— 已换线到 @next）
  5 中英配对：README.zh.md 与 README.md 的兼容性表内容一致

用法:
  python3 scripts/audit-readmes.py [检出根]
  DSH_AUDIT_ROOT=/path python3 scripts/audit-readmes.py
"""
import json, os, pathlib, re, sys

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else
                    os.environ.get('DSH_AUDIT_ROOT',
                    '/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment'))
READMES = ('README.md', 'README.zh.md', 'README.en.md')
ROW = re.compile(r'\|\s*\*\*(?:插件|Plugin)\*\*\s*\|\s*`(?P<name>[a-z0-9-]+)`\s*\*\*(?P<ver>[0-9.]+)\*\*')
LINK = re.compile(r'\]\((?!https?:|#|mailto:)([^)]+)\)')
TAIL = re.compile(r'^## (Compatibility|兼容性)(\s*\(.*\))?\s*$', re.M)
# dsh-wsl-common 是库（无 dsh 字段），不是插件
# dsh-wsl-common 是库（无 dsh 字段）；*.mirror 是同一个仓的另一份检出
EXEMPT = {'dsh-wsl-common'}
EXEMPT_PREFIX = ('dsh-wsl-kit',)

findings = []
checked = {'version': 0, 'link': 0, 'table': 0}

repos = [d for d in sorted(ROOT.iterdir())
         if d.is_dir() and d.name.startswith('dsh-') and (d / '.git').is_dir()]
if not repos:
    print(f'  ★ {ROOT} 下没有仓'); sys.exit(2)

for d in repos:
    if d.name in EXEMPT or d.name.startswith(EXEMPT_PREFIX):
        continue
    pj = d / 'package.json'
    actual = None
    if pj.is_file():
        try: actual = json.loads(pj.read_text(encoding='utf-8')).get('version')
        except Exception: pass

    for f in READMES:
        p = d / f
        if not p.is_file():
            continue
        text = p.read_text(encoding='utf-8', errors='replace')

        # 3 有表吗
        checked['table'] += 1
        if not TAIL.search(text):
            findings.append(('表缺失', d.name, f, '没有 ## Compatibility / ## 兼容性'))

        # 1 版本一致吗
        if actual:
            for m in ROW.finditer(text):
                checked['version'] += 1
                if m.group('ver') != actual:
                    findings.append(('版本不符', d.name, f,
                                     f'README 说 {m.group("ver")} · package.json 是 {actual}'))

        # 2 链接存在吗
        for m in LINK.finditer(text):
            tgt = m.group(1).split('#')[0].strip()
            if not tgt: continue
            checked['link'] += 1
            if not (d / tgt).exists():
                findings.append(('断链', d.name, f, tgt))

        # 4 残留的 @alpha
        if '@alpha' in text:
            findings.append(('过时标签', d.name, f, '仍写着 @alpha'))

        # 5 中英兼容性表一致吗
        if f == 'README.md' and (d / 'README.zh.md').is_file():
            zh = (d / 'README.zh.md').read_text(encoding='utf-8', errors='replace')
            a = [m.group('ver') for m in ROW.finditer(text)]
            b = [m.group('ver') for m in ROW.finditer(zh)]
            if a and b and a != b:
                findings.append(('中英不一致', d.name, 'README.md vs .zh.md', f'{a} vs {b}'))

print(f'  {ROOT}')
print(f'  检查 {len(repos)} 个仓 · 表 {checked["table"]} · 版本行 {checked["version"]} · 链接 {checked["link"]}')
if not findings:
    print('  ✓ 无发现')
    sys.exit(0)

kind = {}
for k, r, f, msg in findings:
    kind.setdefault(k, []).append((r, f, msg))
print(f'  ★ 共 {len(findings)} 项发现:')
for k, items in sorted(kind.items()):
    print(f'     ── {k}: {len(items)} 项')
    for r, f, msg in items[:8]:
        print(f'        {r:26} {f:22} {msg[:56]}')
    if len(items) > 8:
        print(f'        … 还有 {len(items)-8} 项')
sys.exit(1)
