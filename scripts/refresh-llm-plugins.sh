#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
dsh plugin --profile web add github:173787247/dsh-wsl-docker
dsh plugin --profile web add github:173787247/dsh-wsl-hostsvc
dsh plugin --profile web list 2>&1 | grep -E 'docker|hostsvc'
