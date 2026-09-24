#!/usr/bin/env python3
"""Bump 'Latest verified' dsh pin across sibling plugin READMEs; add Compatibility tables where missing."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OLD = "0.1.5-rc.1"
NEW = "0.1.7-alpha.2"
SKIP = {"dsh-wsl-kit", "dsh-wsl-common"}

OPTIONAL = {
    "dsh-wsl-ollama",
    "dsh-wsl-secret",
    "dsh-wsl-media",
    "dsh-wsl-search",
    "dsh-wsl-vecmem",
    "dsh-wsl-k8s",
    "dsh-wsl-llamacpp",
    "dsh-wsl-vllm",
    "dsh-wsl-struct",
    "dsh-wsl-git",
    "dsh-wsl-tmux",
    "dsh-wsl-compose",
    "dsh-wsl-systemd",
    "dsh-wsl-helm",
    "dsh-wsl-terraform",
    "dsh-wsl-rclone",
    "dsh-wsl-db",
    "dsh-wsl-glab",
    "dsh-wsl-playwright",
    "dsh-wsl-mail",
    "dsh-wsl-cal",
    "dsh-wsl-pkg",
    "dsh-wsl-obsidian",
    "dsh-wsl-jev",
    "dsh-wsl-im",
}


def pkg_ver(d: Path) -> str:
    p = d / "package.json"
    if p.is_file():
        return json.loads(p.read_text(encoding="utf-8")).get("version", "0.1.0")
    return "0.1.0"


def compat_en(name: str, ver: str) -> str:
    return (
        "\n## Compatibility\n\n"
        "| Field | Value |\n|-------|-------|\n"
        f"| **Plugin** | `{name}` **{ver}** |\n"
        "| **Minimum dsh** | ≥ **0.1.2** (web UI one-shot `?token=` on Windows relay `:3081`) |\n"
        f"| **Latest verified** | See [dsh-wsl-kit Compatibility](https://github.com/173787247/dsh-wsl-kit#compatibility-2026-09) (currently **`{NEW}`**) — single source of truth for the suite |\n"
        "| **Kit set** | optional (not in `install.sh` / `KIT_SET=daily` by default) |\n"
    )


def compat_zh(name: str, ver: str) -> str:
    return (
        "\n## 兼容性\n\n"
        "| 字段 | 值 |\n|------|----|\n"
        f"| **插件** | `{name}` **{ver}** |\n"
        "| **最低 dsh** | ≥ **0.1.2**（Web UI 一次性 `?token=`，Windows 中继 `:3081`） |\n"
        f"| **最新验证** | 以 [dsh-wsl-kit 兼容性](https://github.com/173787247/dsh-wsl-kit#compatibility-2026-09) 为准（当前 **`{NEW}`**）— 套件唯一真源 |\n"
        "| **套件档位** | 可选（默认不在 `install.sh` / `KIT_SET=daily`） |\n"
    )


def is_zh_readme(path: Path, text: str) -> bool:
    if path.name == "README.zh.md":
        return True
    if path.name == "README.en.md":
        return False
    # Banner can push the English lede past 250 chars — scan a wider head.
    head = text[:2000]
    if "DeepSeek Harness plugin:" in head or re.search(r"(?m)^## Compatibility\s*$", head):
        return False
    if re.search(r"(?m)^## 兼容性\s*$", head):
        return True
    return bool(re.search(r"[\u4e00-\u9fff]", head))


def has_compat(text: str) -> bool:
    return bool(re.search(r"^## (Compatibility|兼容性)\s*$", text, re.M))


def insert_compat(path: Path, block: str) -> bool:
    text = path.read_text(encoding="utf-8")
    if has_compat(text):
        return False
    m = re.search(r"^## (License|许可|许可证)\s*$", text, re.M)
    if m:
        new = text[: m.start()] + block.lstrip("\n") + "\n" + text[m.start() :]
    else:
        new = text.rstrip() + "\n" + block
    if not new.endswith("\n"):
        new += "\n"
    path.write_text(new, encoding="utf-8")
    return True


def ensure_verified_row(path: Path, is_zh: bool) -> bool:
    text = path.read_text(encoding="utf-8")
    if not has_compat(text):
        return False
    if "Latest verified" in text or "最新验证" in text:
        return False
    if is_zh:
        row = (
            f"| **最新验证** | 以 [dsh-wsl-kit 兼容性](https://github.com/173787247/dsh-wsl-kit#compatibility-2026-09) "
            f"为准（当前 **`{NEW}`**）— 套件唯一真源 |\n"
        )
        text2 = re.sub(r"(\| \*\*最低 dsh\*\* \|[^\n]+\n)", r"\1" + row, text, count=1)
        if text2 == text:
            text2 = re.sub(r"(\| \*\*Minimum dsh\*\* \|[^\n]+\n)", r"\1" + row, text, count=1)
    else:
        row = (
            f"| **Latest verified** | See [dsh-wsl-kit Compatibility](https://github.com/173787247/dsh-wsl-kit#compatibility-2026-09) "
            f"(currently **`{NEW}`**) — single source of truth for the suite |\n"
        )
        text2 = re.sub(r"(\| \*\*Minimum dsh\*\* \|[^\n]+\n)", r"\1" + row, text, count=1)
        if text2 == text:
            text2 = re.sub(r"(\| \*\*最低 dsh\*\* \|[^\n]+\n)", r"\1" + row, text, count=1)
    if text2 == text:
        return False
    path.write_text(text2, encoding="utf-8")
    return True


def main() -> None:
    changed_repos: set[str] = set()
    replaced = 0
    inserted = 0
    rows = 0

    for d in sorted(ROOT.iterdir()):
        if not d.is_dir():
            continue
        name = d.name
        if name in SKIP:
            continue
        if not (name.startswith("dsh-wsl-") or name in {"dsh-repeat-stop", "dsh-tool-budget"}):
            continue

        ver = pkg_ver(d)
        for fname in ("README.md", "README.zh.md", "README.en.md"):
            p = d / fname
            if not p.is_file():
                continue
            text = p.read_text(encoding="utf-8")
            new = text.replace(OLD, NEW)
            if new != text:
                p.write_text(new, encoding="utf-8")
                replaced += 1
                changed_repos.add(name)
                text = new

            zh = is_zh_readme(p, text)
            if name in OPTIONAL:
                block = compat_zh(name, ver) if zh else compat_en(name, ver)
                if insert_compat(p, block):
                    inserted += 1
                    changed_repos.add(name)
                    text = p.read_text(encoding="utf-8")
                    zh = is_zh_readme(p, text)

            if ensure_verified_row(p, zh):
                rows += 1
                changed_repos.add(name)

    print(f"replaced_files={replaced} inserted_tables={inserted} verified_rows={rows} repos={len(changed_repos)}")
    for r in sorted(changed_repos):
        print(r)

    stale = []
    for d in ROOT.iterdir():
        if not d.is_dir() or not d.name.startswith("dsh-"):
            continue
        for p in d.glob("README*.md"):
            if OLD in p.read_text(encoding="utf-8", errors="ignore"):
                stale.append(str(p))
    print(f"remaining_stale={len(stale)}")
    for s in stale:
        print(" STALE", s)


if __name__ == "__main__":
    main()
