#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
echo "=== plugins ==="
dsh plugin --profile web list 2>&1 | sed -n '/dependencies:/,/packages/p'
echo "=== ctx ==="
grep -nE 'contextWindow|qwen38|num_ctx' "${HOME}/.dsh/settings.yaml" 2>/dev/null | head -25 || true
echo "=== github ==="
if test -f "${HOME}/.dsh/dsh-wsl-github.env"; then echo yes; else echo no; fi
echo "=== ports ==="
ss -tlnp 2>/dev/null | grep -E '3080|3081' || true
code3080=$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://127.0.0.1:3080/ || echo fail)
code3081=$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 http://127.0.0.1:3081/ || echo fail)
echo "3080=${code3080} 3081=${code3081}"
