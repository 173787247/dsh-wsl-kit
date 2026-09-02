#!/usr/bin/env bash
# Install dsh-wsl-kit plugins into the current dsh profile (GitHub sources).
#
#   KIT_SET=daily|github|full|llm   (default: full — keeps old curl|bash behavior)
#   DSH_PROFILE=web             (default: web)
#
# Examples:
#   curl -fsSL …/install.sh | KIT_SET=daily bash
#   KIT_SET=github bash install.sh
set -euo pipefail

PROFILE="${DSH_PROFILE:-web}"
KIT_SET="${KIT_SET:-full}"

DAILY=(
  "github:173787247/dsh-wsl-env"
  "github:173787247/dsh-wsl-net"
  "github:173787247/dsh-wsl-open"
  "github:173787247/dsh-repeat-stop"
  "github:173787247/dsh-tool-budget"
  "github:173787247/dsh-wsl-clipboard"
  "github:173787247/dsh-wsl-path"
  "github:173787247/dsh-wsl-browser"
  "github:173787247/dsh-wsl-launch"
)

GITHUB_EXTRA=(
  "github:173787247/dsh-wsl-github"
  "github:173787247/dsh-wsl-cred"
  "github:173787247/dsh-wsl-notify"
)

FULL_EXTRA=(
  "github:173787247/dsh-wsl-gpu"
  "github:173787247/dsh-wsl-port"
  "github:173787247/dsh-wsl-distro"
  "github:173787247/dsh-wsl-workspace"
  "github:173787247/dsh-wsl-picker"
  "github:173787247/dsh-wsl-tray"
  "github:173787247/dsh-wsl-expose"
  "github:173787247/dsh-wsl-hostsvc"
  "github:173787247/dsh-wsl-clock"
  "github:173787247/dsh-wsl-dns"
  "github:173787247/dsh-wsl-mnt"
  "github:173787247/dsh-wsl-editor"
  "github:173787247/dsh-wsl-shot"
  "github:173787247/dsh-wsl-docker"
  "github:173787247/dsh-wsl-ssh-agent"
  "github:173787247/dsh-wsl-encoding"
  "github:173787247/dsh-wsl-wslconfig"
  "github:173787247/dsh-wsl-download"
)

LLM_SET=(
  "github:173787247/dsh-wsl-env"
  "github:173787247/dsh-wsl-net"
  "github:173787247/dsh-wsl-hostsvc"
  "github:173787247/dsh-wsl-docker"
  "github:173787247/dsh-wsl-dns"
  "github:173787247/dsh-wsl-clock"
  "github:173787247/dsh-wsl-gpu"
  "github:173787247/dsh-wsl-port"
  "github:173787247/dsh-wsl-expose"
  "github:173787247/dsh-wsl-tray"
  "github:173787247/dsh-wsl-open"
  "github:173787247/dsh-wsl-path"
  "github:173787247/dsh-wsl-browser"
)

PLUGINS=("${DAILY[@]}")
case "${KIT_SET}" in
  daily) ;;
  llm)
    PLUGINS=("${LLM_SET[@]}")
    ;;
  github)
    PLUGINS+=("${GITHUB_EXTRA[@]}")
    ;;
  full)
    PLUGINS+=("${GITHUB_EXTRA[@]}" "${FULL_EXTRA[@]}")
    ;;
  *)
    echo "Unknown KIT_SET=${KIT_SET} (use daily|github|full|llm)" >&2
    exit 1
    ;;
esac

echo "KIT_SET=${KIT_SET}  DSH_PROFILE=${PROFILE}  count=${#PLUGINS[@]}"
for p in "${PLUGINS[@]}"; do
  echo "==> dsh plugin --profile ${PROFILE} add ${p}"
  dsh plugin --profile "${PROFILE}" add "${p}"
done
echo "Done. Restart dsh web and open a new session."
echo "Optional: merge cordis.patch.yml from this repo into your profile."
