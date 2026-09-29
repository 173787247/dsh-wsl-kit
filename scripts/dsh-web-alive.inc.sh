# shellcheck shell=bash
# Shared helpers for dsh ≥0.1.2 launch-token auth (sourced, not executed).
#
# Ports and files are read from the environment on every call rather than
# captured at source time, so the same helpers serve a second instance started
# for a rehearsal. Defaults are the live values.
dsh_web_port() { echo "${DSH_WEB_PORT:-3080}"; }
dsh_relay_port() { echo "${DSH_RELAY_PORT:-3081}"; }
dsh_web_log() { echo "${DSH_WEB_LOG:-/tmp/dsh-web.log}"; }
dsh_ui_url_file() { echo "${DSH_UI_URL_FILE:-/tmp/dsh-ui-url}"; }

dsh_http_up() {
  case "${1:-}" in
    200|301|302|303|401) return 0 ;;
    *) return 1 ;;
  esac
}

# `grep -a` is not optional here. dsh's log picks up NUL bytes, grep then treats
# the file as binary and prints "binary file matches" *instead of the match*,
# and the token line is silently lost. Without -a this function returns the bare
# URL, the bare URL is a 401, and a restart looks like it failed when it worked.
#
# Measured on a real log: 40 NUL bytes, `grep -oE` printed nothing,
# `grep -aoE` printed the token.
dsh_ui_url_from_log() {
  local log="${1:-$(dsh_web_log)}"
  local web; web="$(dsh_web_port)"
  local relay; relay="$(dsh_relay_port)"
  local raw=""
  if [[ -f "$log" ]]; then
    # tail -1 because a restarted process appends another token; the last is current.
    raw="$(grep -aoE "http://127\.0\.0\.1:${web}/\?token=[A-Za-z0-9._~-]+" "$log" | tail -1 || true)"
  fi
  if [[ -n "$raw" ]]; then
    echo "${raw/:${web}\//:${relay}\/}"
  else
    echo "http://127.0.0.1:${relay}/"
  fi
}

# Say whether the URL we hand out actually carries a token. The bare URL is a
# 401 by design, so a caller that cannot tell the two apart will report success
# and then be unable to get back in.
dsh_ui_url_usable() {
  local url="${1:-}"
  [[ "$url" == *"?token="* ]]
}

# Open the URL in the browser the user actually uses.
#
# "Open the default browser" is not the same thing, and on Windows it is not even
# stable: explorer.exe hands the URL to whatever the http ProgId currently
# points at. So Chrome is named explicitly and the default is only the fallback.
#
# DSH_BROWSER overrides the executable entirely.
dsh_open_browser() {
  local url="${1:?url required}"
  local candidates=()

  # Put the URL on the Windows clipboard first. The token is per-process, so the
  # clipboard is the one recovery route that survives everything else going
  # wrong: if the browser opens to the wrong profile, or does not open at all,
  # the address is already where it can be pasted.
  if command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$url" | clip.exe >/dev/null 2>&1 || true
  fi

  # ── Preferred: let Windows open it, not us ────────────────────────────────
  #
  # Do NOT call chrome.exe directly from WSL. Measured 2026-09-29: invoking
  # chrome.exe over interop either attaches to nothing (a new window or a
  # different profile, so the tab the user is looking at never updates) or
  # hangs, and either way the shell returns 0 immediately -- the restart
  # reports success while the browser is still on a dead token. That is why a
  # restart that "worked" still needed the desktop shortcut clicked.
  #
  # `Start-Process` goes through the Windows shell, which hands the URL to the
  # browser that is already running with the profile the user actually uses,
  # which is exactly what start-dsh-web.ps1 has always done. Same behaviour
  # from both entry points.
  if command -v powershell.exe >/dev/null 2>&1; then
    # -EncodedCommand avoids every layer of WSL->Windows quoting.
    local ps url_b64
    url_b64="$(printf '%s' "$url" | base64 -w0)"
    ps="\$u=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('${url_b64}')); Start-Process \$u"
    powershell.exe -NoProfile -NonInteractive -EncodedCommand \
      "$(printf '%s' "$ps" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)" \
      >/dev/null 2>&1 &
    return 0
  fi

  if [[ -n "${DSH_BROWSER:-}" ]]; then
    candidates+=("${DSH_BROWSER}")
  else
    candidates+=(
      "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
      "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
      "/mnt/c/Users/${USER}/AppData/Local/Google/Chrome/Application/chrome.exe"
    )
  fi

  for exe in "${candidates[@]}"; do
    if [[ -x "$exe" ]]; then
      "$exe" "$url" >/dev/null 2>&1 &
      return 0
    fi
  done

  # No Chrome found. Fall back to whatever handles http, and say so, because a
  # tab in an unexpected browser is confusing if you did not ask for it.
  if command -v explorer.exe >/dev/null 2>&1; then
    echo "note: Chrome not found; opening the default browser instead" >&2
    explorer.exe "$url" >/dev/null 2>&1 || true
    return 0
  fi

  echo "no browser could be opened from here; the URL is on the clipboard and is ${url}" >&2
  return 1
}

dsh_write_ui_url() {
  local url
  url="$(dsh_ui_url_from_log "${1:-$(dsh_web_log)}")"
  printf '%s\n' "$url" > "$(dsh_ui_url_file)"
  if ! dsh_ui_url_usable "$url"; then
    echo "warning: no token found in ${1:-$(dsh_web_log)}; this URL returns 401" >&2
    echo "         the log may predate the running process -- check it was started with output to that file" >&2
  fi
  echo "$url"
}
