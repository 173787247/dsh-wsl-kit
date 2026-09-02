#!/usr/bin/env bash
set -euo pipefail
echo "=== settings ollama models ==="
python3 - <<'PY'
from pathlib import Path
import re
text = Path.home().joinpath(".dsh/settings.yaml").read_text(encoding="utf-8")
# print ollama section roughly
m = re.search(r"(?ms)^    ollama:.*?(?=^\S|\Z)", text)
print(m.group(0) if m else text[:2000])
PY
echo "=== ollama tags ==="
curl --noproxy '*' -s http://127.0.0.1:11434/api/tags | python3 - <<'PY'
import sys, json
d = json.load(sys.stdin)
for m in d.get("models", []):
    print(m.get("name"), "size=", m.get("size"))
PY
