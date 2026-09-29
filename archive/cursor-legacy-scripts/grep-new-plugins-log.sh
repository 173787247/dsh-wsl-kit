#!/usr/bin/env bash
set -euo pipefail
sleep 2
grep -E 'dsh-wsl-(ollama|media|search|vecmem|k8s|secret)' /tmp/dsh-web.log | tail -30
