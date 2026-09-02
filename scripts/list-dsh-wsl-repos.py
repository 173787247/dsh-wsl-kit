import json
import subprocess
import sys

raw = subprocess.check_output(
    ["gh", "api", "users/173787247/repos?per_page=100&sort=created&direction=desc"],
    text=True,
)
repos = json.loads(raw)
print("fetched", len(repos))
for r in repos:
    name = r.get("name", "")
    if name.startswith("dsh-wsl") or name.startswith("dsh-"):
        if "wsl" in name or name in {"dsh-wsl-common", "dsh-wsl-kit"}:
            print(r["created_at"][:10], name, r.get("html_url", ""))
