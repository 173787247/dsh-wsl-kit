#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
echo "=== dsh web ==="
pgrep -af 'node.*/dsh web' || echo "dsh-web-down"
echo "=== plugin versions (see also check-plugin-versions.sh) ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/check-plugin-versions.sh" || true
echo "=== plugins ==="
dsh plugin --profile web list 2>&1 | sed -n '/dependencies:/,/packages/p' || true
echo "=== tray ==="
ls -la ~/.dsh/tray 2>/dev/null || echo "no-tray-dir"
echo "=== profile files ==="
ls -la ~/.dsh/profiles/web/ 2>/dev/null | head -40
echo "=== settings default model ==="
python3 - <<'PY' || true
from pathlib import Path
p = Path.home()/".dsh"/"settings.yaml"
if not p.exists():
    print("settings: missing")
else:
    t = p.read_text(encoding="utf-8")
    inb = False
    model = provider = ""
    for line in t.splitlines():
        if line.startswith("agent-default-model:"):
            inb = True
            continue
        if inb and line and not line[0].isspace():
            break
        if not inb:
            continue
        if line.strip().startswith("provider:"):
            provider = line.split(":",1)[1].strip()
        if line.strip().startswith("model:"):
            model = line.split(":",1)[1].strip()
    print(f"default={provider}/{model}")
    if model == "deepseek-flash":
        print("default_model: OK (deepseek-flash)")
    elif model:
        print(f"WARN: prefer deepseek-flash for interactive DSH (now {model})")
    else:
        print("WARN: could not parse agent-default-model")
PY
echo "=== ui token url ==="
if [[ -f /tmp/dsh-ui-url ]]; then
  u="$(cat /tmp/dsh-ui-url)"
  if [[ "$u" == *token=* ]]; then
    echo "OPEN_THIS_URL=${u}"
    echo "ui_token: OK"
  else
    echo "WARN: /tmp/dsh-ui-url has no token — bash ${SCRIPT_DIR}/restart-dsh-web.sh"
  fi
else
  echo "WARN: no /tmp/dsh-ui-url — bash ${SCRIPT_DIR}/restart-dsh-web.sh"
fi
echo "=== settings ollama ctx ==="
grep -A3 'qwen38-27b-local' ~/.dsh/settings.yaml | head -8 || true
echo "=== host_reach smoke ==="
node /mnt/c/Users/rchua/Desktop/AIFullStackDevelopment/dsh-wsl-kit/scripts/run-host-reach.mjs 2>&1 | tail -30
