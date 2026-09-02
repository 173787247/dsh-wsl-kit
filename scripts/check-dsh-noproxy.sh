#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
echo "=== processes ==="
pgrep -af 'dsh web' || echo DOWN
echo "=== ss ==="
ss -tlnp | grep -E '3000|3080' || echo 'no 3000/3080'
echo "=== curl noproxy ==="
curl --noproxy '*' -s -o /dev/null -w "3080=%{http_code}\n" --connect-timeout 2 http://127.0.0.1:3080/ || echo "3080=fail"
curl --noproxy '*' -s -o /dev/null -w "3000=%{http_code}\n" --connect-timeout 2 http://127.0.0.1:3000/ || echo "3000=fail"
curl --noproxy '*' -sI http://127.0.0.1:3080/ 2>&1 | head -8 || true
echo "=== who 3000 ==="
ss -tlnp | grep 3000 || true
fuser -v 3000/tcp 2>&1 || true
