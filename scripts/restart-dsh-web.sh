#!/usr/bin/env bash
set -euo pipefail

# Windows interop paths, re-added explicitly.
#
# WSL appends the Windows PATH when a process is started from Windows, and every
# interop tool depends on it: clip.exe, powershell.exe, explorer.exe, cmd.exe.
# A process started through the detached restart does NOT get that -- it inherits
# systemd's minimal environment -- so after the first detached restart the whole
# set became unreachable from inside dsh:
#
#   $ command -v powershell.exe     -> nothing
#   $ echo $PATH | grep -c /mnt/c   -> 0
#
# The symptom that surfaced first was the clipboard reporting success while
# /tmp/dsh-ui-url never reached Windows: dsh_open_browser's `command -v clip.exe`
# guard passed by simply doing nothing, which is what a guard should do and also
# why it stayed invisible.
#
# Only added when the directory exists, so a non-WSL host is unaffected, and
# only when absent, so a PATH that already has them is left alone.
for _d in /mnt/c/WINDOWS/system32 /mnt/c/WINDOWS \
          /mnt/c/WINDOWS/System32/Wbem \
          /mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0 \
          /mnt/c/WINDOWS/System32/OpenSSH; do
  case ":${PATH}:" in
    *":${_d}:"*) ;;
    *) [[ -d "$_d" ]] && PATH="${PATH}:${_d}" ;;
  esac
done
unset _d

export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
export NODE_USE_ENV_PROXY=1
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-ollama}"
# Loopback only. Inheriting Clash RFC1918 NO_PROXY globs (10.*, 172.16.*, …)
# makes Node fetch bypass the proxy and TRANSPORT-timeout api.deepseek.com.
export NO_PROXY="127.0.0.1,localhost"
export no_proxy="$NO_PROXY"

# Credentials and per-plugin config, from one file first: ~/.dsh/.env
#
# It used to be dsh-wsl-im.env plus dsh-wsl-jev.env plus .credentials.yaml --
# three places for nineteen keys, and the next plugin would have made a fourth.
# The consolidated file has three sections inside it (secrets / feature flags /
# proxy) so the flags can be handed to someone without the secrets.
#
# The two old files are still sourced afterwards, so an existing install keeps
# working and a plugin can override a single value by keeping its own .env.
#
# Later files win. CRLF is stripped because these get edited on the Windows side.
# plugin-flags.env is sourced explicitly rather than living in .env, because dsh
# reads ~/.dsh/.env itself and refuses to start if it finds a DSH_-prefixed name
# there (BOOTSTRAP_PREFIXES in dsh-app-boot). The only names it exempts in that
# file are HTTP_PROXY, HTTPS_PROXY, ALL_PROXY and NO_PROXY.
#
#   Error: dsh: ~/.dsh/.env sets "DSH_IM_DINGTALK", which only the launching
#          environment may set
#
# Consolidating the old per-plugin files into .env put twelve DSH_* names there
# and made every subsequent start fail — the running process was unaffected only
# because it predated the file. Sourcing them here is an export from the
# launching environment, which is what dsh asks for.
for f in "${HOME}/.dsh/.env" \
         "${HOME}/.dsh/plugin-flags.env" \
         "${HOME}/.dsh/dsh-wsl-im.env" \
         "${HOME}/.dsh/dsh-wsl-jev.env"; do
  if [[ -f "$f" ]]; then
    set -a
    # shellcheck disable=SC1090
    source <(tr -d '\r' < "$f")
    set +a
  fi
done

# Ports, log and URL file are parameters with the live values as defaults, so a
# second instance can be started and restarted on another port without touching
# the one in use. That matters because a restart is the one operation that can
# take dsh down, and until now there was no way to rehearse it: every path in
# this script and in dsh-web-alive.inc.sh named 3080 and 3081 outright.
#
#   DSH_WEB_PORT=3090 DSH_RELAY_PORT=3091 \
#   DSH_WEB_LOG=/tmp/dsh-web-3090.log DSH_UI_URL_FILE=/tmp/dsh-ui-url-3090 \
#     bash scripts/restart-dsh-web.sh
export DSH_WEB_PORT="${DSH_WEB_PORT:-3080}"
export DSH_RELAY_PORT="${DSH_RELAY_PORT:-3081}"
export DSH_WEB_LOG="${DSH_WEB_LOG:-/tmp/dsh-web.log}"
export DSH_UI_URL_FILE="${DSH_UI_URL_FILE:-/tmp/dsh-ui-url}"

# Scoped to this port. The original pattern was 'node.*/dsh web', which kills
# every instance on the machine -- fine when there is only one, and a way to
# take down the live server while testing a second one.
#
# The terminator is [^0-9] rather than an end anchor, because the real command
# line continues past the port:
#
#   node .../dsh web --no-open --port 3080 --trusted-host 127.0.0.1:3081
#
# An earlier version of this line ended the pattern with $, which matched
# nothing at all -- the restart would have spawned a second instance that could
# not bind, and reported a port conflict instead of a restart. Verified against
# the running process: see the pattern checks in the kit's own notes.
pkill -f "dsh web .*--port ${DSH_WEB_PORT}([^0-9]|\$)" 2>/dev/null || true
pkill -f "dsh-port-relay.*${DSH_RELAY_PORT}" 2>/dev/null || true
sleep 1

setsid nohup dsh web --no-open --port "${DSH_WEB_PORT}" \
  --trusted-host "127.0.0.1:${DSH_RELAY_PORT}" \
  >> "${DSH_WEB_LOG}" 2>&1 < /dev/null &
DSH_PID=$!
echo "spawned shell pid=$DSH_PID (port ${DSH_WEB_PORT})"
sleep 4
REAL="$(pgrep -n -f "dsh web .*--port ${DSH_WEB_PORT}([^0-9]|\$)" || true)"
echo "node pid=${REAL:-none}"
ss -tlnp | grep "${DSH_WEB_PORT}" || echo "no ${DSH_WEB_PORT} yet"

for i in 1 2 3 4 5 6; do
  sleep 5
  if pgrep -f "dsh web .*--port ${DSH_WEB_PORT}([^0-9]|\$)" >/dev/null; then
    echo "t=$((i*5))s alive code=$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' --connect-timeout 2 "http://127.0.0.1:${DSH_WEB_PORT}/" || echo fail)"
  else
    echo "t=$((i*5))s DEAD"
    tail -20 "${DSH_WEB_LOG}"
    exit 1
  fi
done

# SCRIPT_DIR, not the Windows checkout. This line used to name
# /mnt/c/.../dsh-wsl-kit/scripts/dsh-port-relay.py, so a script running from the
# WSL clone still read the relay out of the other clone -- one of the two places
# the two copies could disagree, and the one that cost a working fix earlier
# today when a sync copied the older file back over it.
SCRIPT_DIR_RELAY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sed 's/\r$//' "${SCRIPT_DIR_RELAY}/dsh-port-relay.py" > "/tmp/dsh-port-relay-${DSH_RELAY_PORT}.py"
setsid nohup python3 "/tmp/dsh-port-relay-${DSH_RELAY_PORT}.py" \
  --listen "${DSH_RELAY_PORT}" --target "${DSH_WEB_PORT}" \
  >> "/tmp/dsh-relay-${DSH_RELAY_PORT}.log" 2>&1 < /dev/null &
sleep 1
echo "relay=$(pgrep -n -f "dsh-port-relay-${DSH_RELAY_PORT}" || echo none)"
curl --noproxy '*' -s -o /dev/null -w "${DSH_WEB_PORT}=%{http_code} " --connect-timeout 3 "http://127.0.0.1:${DSH_WEB_PORT}/" || echo -n "${DSH_WEB_PORT}=fail "
curl --noproxy '*' -s -o /dev/null -w "${DSH_RELAY_PORT}=%{http_code}\n" --connect-timeout 3 "http://127.0.0.1:${DSH_RELAY_PORT}/" || echo "${DSH_RELAY_PORT}=fail"
# shellcheck source=dsh-web-alive.inc.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/dsh-web-alive.inc.sh"
ui="$(dsh_write_ui_url "${DSH_WEB_LOG}")"
echo "OK — open ${ui}"
echo "(dsh ≥0.1.2: bare :${DSH_RELAY_PORT} is 401; token is one-shot per process, also in ${DSH_UI_URL_FILE})"
