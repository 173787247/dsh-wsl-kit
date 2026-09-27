# shellcheck shell=bash
# Shared helpers for dsh ≥0.1.2 launch-token auth (sourced, not executed).

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
  local log="${1:-/tmp/dsh-web.log}"
  local raw=""
  if [[ -f "$log" ]]; then
    # tail -1 because a restarted process appends another token; the last is current.
    raw="$(grep -aoE 'http://127\.0\.0\.1:3080/\?token=[A-Za-z0-9._~-]+' "$log" | tail -1 || true)"
  fi
  if [[ -n "$raw" ]]; then
    echo "${raw/3080/3081}"
  else
    echo "http://127.0.0.1:3081/"
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

  if [[ -n "${DSH_BROWSER:-}" ]]; then
    candidates+=("${DSH_BROWSER}")
  else
    candidates+=(
      "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
      "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
      "${HOME}/AppData/Local/Google/Chrome/Application/chrome.exe"
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

  echo "no browser could be opened from here; the URL is ${url}" >&2
  return 1
}

dsh_write_ui_url() {
  local url
  url="$(dsh_ui_url_from_log "${1:-/tmp/dsh-web.log}")"
  printf '%s\n' "$url" > /tmp/dsh-ui-url
  if ! dsh_ui_url_usable "$url"; then
    echo "warning: no token found in ${1:-/tmp/dsh-web.log}; this URL returns 401" >&2
    echo "         the log may predate the running process -- check it was started with output to that file" >&2
  fi
  echo "$url"
}
