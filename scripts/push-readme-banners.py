#!/usr/bin/env python3
"""Commit + push README kit-banner updates for every dirty dsh-wsl-* repo."""
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MSG = "docs: link kit Install set banner (daily|llm|github|full)"


def run(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, text=True, capture_output=True)


def main() -> None:
    for d in sorted(ROOT.glob("dsh-wsl-*")):
        if not (d / ".git").is_dir():
            continue
        st = run(d, "git", "status", "--porcelain")
        if not st.stdout.strip():
            continue
        files = []
        for line in st.stdout.splitlines():
            path = line[3:].strip()
            if path.startswith("README"):
                files.append(path)
        # hostsvc may have more than banner
        if d.name == "dsh-wsl-hostsvc":
            files = [p for p in st.stdout.splitlines() for p in [p[3:].strip()] if p.startswith("README")]
        if d.name == "dsh-wsl-kit":
            # handled separately if needed
            pass
        if not files and d.name != "dsh-wsl-kit":
            # any README change
            files = [
                line[3:].strip()
                for line in st.stdout.splitlines()
                if "README" in line
            ]
        if not files:
            continue
        run(d, "git", "add", *files)
        c = run(d, "git", "commit", "-m", MSG)
        if c.returncode != 0:
            print("skip", d.name, (c.stderr or c.stdout)[:200])
            continue
        p = run(d, "git", "push", "origin", "HEAD")
        print(("OK" if p.returncode == 0 else "PUSHFAIL"), d.name)


if __name__ == "__main__":
    main()
