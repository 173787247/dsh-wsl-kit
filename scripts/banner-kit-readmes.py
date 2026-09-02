#!/usr/bin/env python3
"""Insert a unified kit banner into every dsh-wsl-* plugin README (idempotent)."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKIP = {"dsh-wsl-kit", "dsh-wsl-common"}

BANNER_EN = (
    "> **Install set:** part of "
    "[dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit). "
    "Prefer `KIT_SET=daily` | `llm` | `github` | `full` "
    "(see kit README). Fault tree: "
    "[TROUBLESHOOTING.md](https://github.com/173787247/dsh-wsl-kit/blob/master/docs/TROUBLESHOOTING.md).\n"
)

BANNER_ZH = (
    "> **套件安装：** 见 "
    "[dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit)。"
    "推荐 `KIT_SET=daily` | `llm` | `github` | `full`。"
    "故障树："
    "[TROUBLESHOOTING.zh.md](https://github.com/173787247/dsh-wsl-kit/blob/master/docs/TROUBLESHOOTING.zh.md)。\n"
)

MARKER_EN = "> **Install set:**"
MARKER_ZH = "> **套件安装：**"


def insert_banner(path: Path, banner: str, marker: str) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    if marker in text:
        return False
    lines = text.splitlines(keepends=True)
    if not lines:
        return False
    # After first heading line
    out: list[str] = []
    inserted = False
    for i, line in enumerate(lines):
        out.append(line)
        if not inserted and line.startswith("# "):
            # keep one blank line then banner
            if i + 1 < len(lines) and lines[i + 1].strip() == "":
                pass
            else:
                out.append("\n")
            out.append(banner)
            if not banner.endswith("\n"):
                out.append("\n")
            out.append("\n")
            inserted = True
    if not inserted:
        return False
    path.write_text("".join(out), encoding="utf-8")
    return True


def main() -> None:
    changed = []
    for d in sorted(ROOT.glob("dsh-wsl-*")):
        if not d.is_dir() or d.name in SKIP:
            continue
        for name, banner, marker in (
            ("README.md", BANNER_EN, MARKER_EN),
            ("README.zh.md", BANNER_ZH, MARKER_ZH),
        ):
            p = d / name
            if insert_banner(p, banner, marker):
                changed.append(str(p.relative_to(ROOT)))
    print(f"updated {len(changed)} files")
    for c in changed:
        print(c)


if __name__ == "__main__":
    main()
