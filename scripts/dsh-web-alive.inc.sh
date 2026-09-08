# shellcheck shell=bash
# Shared helpers for dsh ≥0.1.2 launch-token auth (sourced, not executed).

dsh_http_up() {
  case "${1:-}" in
    200|301|302|303|401) return 0 ;;
    *) return 1 ;;
  esac
}

dsh_ui_url_from_log() {
  local log="${1:-/tmp/dsh-web.log}"
  local raw=""
  if [[ -f "$log" ]]; then
    raw="$(grep -oE 'http://127\.0\.0\.1:3080/\?token=[A-Za-z0-9._~-]+' "$log" | tail -1 || true)"
  fi
  if [[ -n "$raw" ]]; then
    echo "${raw/3080/3081}"
  else
    echo "http://127.0.0.1:3081/"
  fi
}

dsh_write_ui_url() {
  local url
  url="$(dsh_ui_url_from_log "${1:-/tmp/dsh-web.log}")"
  printf '%s\n' "$url" > /tmp/dsh-ui-url
  echo "$url"
}
