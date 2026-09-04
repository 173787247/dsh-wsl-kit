#!/usr/bin/env bash
# Compare installed dsh web profile plugin versions vs sibling checkouts (and floor table).
# Exit 1 if any STALE or MISSING among tracked plugins.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT="${DSH_WSL_ROOT:-$(cd "${KIT_DIR}/.." && pwd)}"
PROFILE_NM="${HOME}/.dsh/profiles/web/node_modules"

# Minimum expected versions when sibling checkout is absent
declare -A FLOOR=(
  [dsh-wsl-net]=0.5.1
  [dsh-wsl-dns]=0.2.0
  [dsh-wsl-clock]=0.2.0
  [dsh-wsl-workspace]=0.2.0
  [dsh-wsl-distro]=0.2.0
  [dsh-wsl-github]=0.2.0
  [dsh-wsl-hostsvc]=0.4.2
  [dsh-wsl-docker]=0.2.2
  [dsh-wsl-gpu]=0.2.1
  [dsh-wsl-tray]=0.2.2
  [dsh-wsl-mnt]=0.2.0
  [dsh-wsl-encoding]=0.2.0
  [dsh-wsl-ssh-agent]=0.2.0
  [dsh-wsl-path]=0.2.0
  [dsh-wsl-cred]=0.2.0
  [dsh-wsl-port]=0.2.1
)

TRACKED=(
  dsh-wsl-net
  dsh-wsl-dns
  dsh-wsl-clock
  dsh-wsl-workspace
  dsh-wsl-distro
  dsh-wsl-github
  dsh-wsl-hostsvc
  dsh-wsl-docker
  dsh-wsl-gpu
  dsh-wsl-tray
  dsh-wsl-mnt
  dsh-wsl-encoding
  dsh-wsl-ssh-agent
  dsh-wsl-path
  dsh-wsl-cred
  dsh-wsl-port
)

version_ge() {
  # return 0 if $1 >= $2 (semver-ish dotted ints)
  python3 - "$1" "$2" <<'PY'
import sys
def parts(s):
    out=[]
    for p in str(s).split("."):
        try: out.append(int(p))
        except ValueError: out.append(0)
    return out
a, b = parts(sys.argv[1]), parts(sys.argv[2])
n=max(len(a),len(b))
a+=[0]*(n-len(a)); b+=[0]*(n-len(b))
sys.exit(0 if a>=b else 1)
PY
}

read_pkg_ver() {
  local path="$1"
  if [[ -f "$path" ]]; then
    python3 -c "import json; print(json.load(open('$path'))['version'])"
  else
    echo ""
  fi
}

echo "check-plugin-versions: ROOT=${ROOT}"
echo "profile: ${PROFILE_NM}"
echo ""

failed=0
printf "%-22s %-10s %-10s %s\n" "plugin" "installed" "expected" "status"
printf "%-22s %-10s %-10s %s\n" "------" "---------" "--------" "------"

for name in "${TRACKED[@]}"; do
  installed="$(read_pkg_ver "${PROFILE_NM}/${name}/package.json")"
  sibling="$(read_pkg_ver "${ROOT}/${name}/package.json")"
  expected="${sibling:-${FLOOR[$name]}}"
  if [[ -z "$installed" ]]; then
    status="MISSING"
    failed=1
    installed="-"
  elif ! version_ge "$installed" "$expected"; then
    status="STALE"
    failed=1
  else
    status="OK"
  fi
  src="floor"
  [[ -n "$sibling" ]] && src="sibling"
  printf "%-22s %-10s %-10s %s (%s)\n" "$name" "$installed" "$expected" "$status" "$src"
done

echo ""
if [[ "$failed" -ne 0 ]]; then
  echo "RESULT: drift detected — dsh plugin --profile web add github:173787247/<name> then bash scripts/restart-dsh-web.sh"
  echo "Also see scripts/post-install-check.sh for process/settings."
  exit 1
fi
echo "RESULT: all tracked plugins OK"
exit 0
