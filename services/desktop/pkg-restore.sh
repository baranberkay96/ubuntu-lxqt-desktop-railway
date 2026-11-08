#!/usr/bin/env bash
# railway-pkg-restore: reinstalls distribution packages after a redeploy.
#
# Only /config (the home directory) is on the Railway volume. Packages
# installed with apt or apk live in the image and are gone after every
# redeploy. This script, started in the background by railway-start once the
# desktop is up, reinstalls the packages listed in:
#   - the APT_PACKAGES (Debian, Ubuntu, Kali) or APK_PACKAGES (Alpine)
#     variable, space or comma separated, and
#   - ~/.config/railway-desktop/packages (one or more per line, '#' comments).
# The home-directory list is ignored when HARDEN_DESKTOP or DISABLE_SUDO is
# on, because there the desktop user must not be able to install packages.
set -Eeuo pipefail

readonly LIST_FILE="/config/.config/railway-desktop/packages"
readonly LOG_DIR="/var/log/railway-desktop"
readonly LOG_FILE="${LOG_DIR}/pkg-restore.log"
readonly DPKG_LOCK_TIMEOUT=600
readonly NAME_PATTERN='^[a-z0-9][a-z0-9+._-]+(=[A-Za-z0-9.+:~_-]+)?$'

log() { printf '[railway-pkg-restore] %s\n' "$*" >&2; }

is_true() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    1 | true | yes | on) return 0 ;;
    *) return 1 ;;
  esac
}

# Prints "apt" or "apk", whichever package manager the image has.
package_manager() {
  if command -v apt-get > /dev/null 2>&1; then
    printf 'apt\n'
  elif command -v apk > /dev/null 2>&1; then
    printf 'apk\n'
  else
    return 1
  fi
}

# Prints the requested packages, one per line, without duplicates.
# $1 = the value of the package variable.
collect_packages() {
  local requested="$1"
  local -a words=() parts=()
  local -A seen=()
  local line word

  if [[ -n "$requested" ]]; then
    read -r -a words <<< "${requested//,/ }"
  fi
  if is_true "${HARDEN_DESKTOP:-}" || is_true "${DISABLE_SUDO:-}"; then
    if [[ -e "$LIST_FILE" ]]; then
      log "Desktop is hardened: ignoring ${LIST_FILE}."
    fi
  elif [[ -f "$LIST_FILE" && ! -L "$LIST_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      read -r -a parts <<< "$line"
      words+=("${parts[@]}")
    done < "$LIST_FILE"
  fi

  for word in "${words[@]}"; do
    if [[ ! "$word" =~ $NAME_PATTERN ]]; then
      log "Skipping invalid package name: '${word:0:64}'"
      continue
    fi
    if [[ -z "${seen[$word]:-}" ]]; then
      seen[$word]=1
      printf '%s\n' "$word"
    fi
  done
}

install_packages() {
  local manager="$1"
  shift
  case "$manager" in
    apt)
      DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout="$DPKG_LOCK_TIMEOUT" update &&
        DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout="$DPKG_LOCK_TIMEOUT" \
          install -y --no-install-recommends "$@"
      ;;
    apk) apk add --no-cache "$@" ;;
  esac
}

main() {
  local manager requested
  local -a pkgs=()

  manager="$(package_manager)" || { log "No apt-get or apk in this image."; exit 0; }
  if [[ "$manager" == apt ]]; then
    requested="${APT_PACKAGES:-}"
  else
    requested="${APK_PACKAGES:-}"
  fi
  mapfile -t pkgs < <(collect_packages "$requested")
  (( ${#pkgs[@]} > 0 )) || exit 0

  install -d -m 0755 "$LOG_DIR"
  log "Reinstalling ${#pkgs[@]} package(s) with ${manager}: ${pkgs[*]} (log: ${LOG_FILE})"
  if install_packages "$manager" "${pkgs[@]}" > "$LOG_FILE" 2>&1; then
    log "Packages restored."
  else
    log "WARNING: package restore failed. See ${LOG_FILE} (tail below)."
    tail -n 15 "$LOG_FILE" >&2 || true
  fi
}

main "$@"
