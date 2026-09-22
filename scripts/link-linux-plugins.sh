#!/usr/bin/env bash
# Link optional Linux/local dsh-wsl-* plugins into the web profile.
# Override: DSH_LINK_PLUGINS="dsh-wsl-ollama dsh-wsl-secret" bash scripts/link-linux-plugins.sh
set -euo pipefail
export PATH="${HOME}/.local/bin:${PATH}"
BASE="${DSH_PLUGINS_BASE:-/mnt/c/Users/rchua/Desktop/AIFullStackDevelopment}"

DEFAULT_PLUGINS=(
  dsh-wsl-ollama
  dsh-wsl-media
  dsh-wsl-search
  dsh-wsl-vecmem
  dsh-wsl-k8s
  dsh-wsl-secret
  dsh-wsl-llamacpp
  dsh-wsl-vllm
  dsh-wsl-struct
  dsh-wsl-git
  dsh-wsl-tmux
  dsh-wsl-compose
  dsh-wsl-systemd
  dsh-wsl-helm
  dsh-wsl-terraform
  dsh-wsl-rclone
  dsh-wsl-db
  dsh-wsl-glab
  dsh-wsl-playwright
  dsh-wsl-mail
  dsh-wsl-cal
  dsh-wsl-pkg
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
dsh plugin --profile web list 2>/dev/null | grep -E 'dsh-wsl-' || true
