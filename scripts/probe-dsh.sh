#!/usr/bin/env bash
set -euo pipefail
echo "=== processes ==="
pgrep -af 'node.*/dsh web' || echo "dsh DOWN"
pgrep -af 'dsh-port-relay' || echo "relay DOWN"
echo "=== listeners ==="
ss -tlnp | grep -E '3080|3081' || true
echo "=== python connect 3080 ==="
python3 - <<'PY'
import socket
try:
    s = socket.create_connection(("127.0.0.1", 3080), 5)
    print("ok", s.getpeername())
    s.close()
except Exception as e:
    print("fail", type(e).__name__, e)
PY
echo "=== curl ==="
curl --noproxy '*' -s -o /dev/null -w "3080=%{http_code} 3081=%{http_code}\n" --connect-timeout 3 http://127.0.0.1:3080/ http://127.0.0.1:3081/ || true
