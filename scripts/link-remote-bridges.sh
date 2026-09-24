#!/usr/bin/env bash
# Link remote-bridge plugins into the web profile.
# Override: DSH_LINK_PLUGINS="dsh-remote-ssh" bash scripts/link-remote-bridges.sh
set -euo pipefail
export PATH="${HOME}/.local/bin:${PATH}"
BASE="${DSH_PLUGINS_BASE:-/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment}"

DEFAULT_PLUGINS=(
  dsh-remote-ssh
  dsh-mac-companion
  dsh-device-bridge
)

if [[ -n "${DSH_LINK_PLUGINS:-}" ]]; then
  # shellcheck disable=SC2206
  PLUGINS=( ${DSH_LINK_PLUGINS} )
else
  PLUGINS=( "${DEFAULT_PLUGINS[@]}" )
fi

for p in "${PLUGINS[@]}"; do
  echo "=== add $p ==="
  if [[ ! -d "${BASE}/${p}" ]]; then
    echo "skip missing: ${BASE}/${p}"
    continue
  fi
  dsh plugin --profile web add "${BASE}/${p}" || true
done

echo "=== listed (grep) ==="
dsh plugin --profile web list 2>/dev/null | grep -E 'dsh-remote-ssh|dsh-mac-companion|dsh-device-bridge' || true
