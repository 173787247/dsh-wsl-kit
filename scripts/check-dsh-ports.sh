#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
echo "=== dsh process ==="
pgrep -af 'node.*/dsh web' || echo DOWN
echo "=== listeners ==="
ss -tlnp 2>/dev/null | grep -E ':3000|:3080' || true
echo "=== curl ==="
curl -s -o /dev/null -w "3080=%{http_code}\n" --connect-timeout 2 http://127.0.0.1:3080/ || echo "3080=fail"
curl -s -o /dev/null -w "3000=%{http_code}\n" --connect-timeout 2 http://127.0.0.1:3000/ || echo "3000=fail"
