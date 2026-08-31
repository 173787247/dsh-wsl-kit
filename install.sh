#!/usr/bin/env bash
# Install the full WSL kit into the current dsh web profile (GitHub sources).
set -euo pipefail
PROFILE="${DSH_PROFILE:-web}"
PLUGINS=(
  "github:173787247/dsh-wsl-env"
  "github:173787247/dsh-wsl-net"
  "github:173787247/dsh-wsl-open"
  "github:173787247/dsh-repeat-stop"
  "github:173787247/dsh-tool-budget"
  "github:173787247/dsh-wsl-clipboard"
  "github:173787247/dsh-wsl-launch"
  "github:173787247/dsh-wsl-path"
  "github:173787247/dsh-wsl-gpu"
  "github:173787247/dsh-wsl-port"
  "github:173787247/dsh-wsl-distro"
  "github:173787247/dsh-wsl-cred"
  "github:173787247/dsh-wsl-github"
  "github:173787247/dsh-wsl-notify"
  "github:173787247/dsh-wsl-browser"
  # WSL UI counterparts
  "github:173787247/dsh-wsl-workspace"
  "github:173787247/dsh-wsl-picker"
  "github:173787247/dsh-wsl-tray"
  "github:173787247/dsh-wsl-expose"
  # Tier 1 diagnostics / bridge
  "github:173787247/dsh-wsl-hostsvc"
  "github:173787247/dsh-wsl-clock"
  "github:173787247/dsh-wsl-dns"
  "github:173787247/dsh-wsl-mnt"
  "github:173787247/dsh-wsl-editor"
  "github:173787247/dsh-wsl-shot"
  # Tier 2
  "github:173787247/dsh-wsl-docker"
  "github:173787247/dsh-wsl-ssh-agent"
  "github:173787247/dsh-wsl-encoding"
  "github:173787247/dsh-wsl-wslconfig"
  "github:173787247/dsh-wsl-download"
)
for p in "${PLUGINS[@]}"; do
  echo "==> dsh plugin --profile ${PROFILE} add ${p}"
  dsh plugin --profile "${PROFILE}" add "${p}"
done
echo "Done. Restart dsh web and open a new session."
echo "Optional: merge cordis.patch.yml from this repo into your profile."
