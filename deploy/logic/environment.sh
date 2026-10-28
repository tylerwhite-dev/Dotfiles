#!/usr/bin/env bash

# Detects the Linux family and system name from /etc/os-release.
_environment_detect_linux() {
  local family_result_name="$1"
  local name_result_name="$2"

  if [[ ! -r /etc/os-release ]]; then
    return 1
  fi

  local ID=""
  local ID_LIKE=""
  local PRETTY_NAME=""
  local family_name=""

  # /etc/os-release contains shell-compatible variable assignments.
  # shellcheck disable=SC1091
  source /etc/os-release

  local identifiers=" ${ID,,} ${ID_LIKE,,} "
  if [[ "$identifiers" == *" arch "* ]]; then
    family_name="arch"
  elif [[ "$identifiers" == *" debian "* || "$identifiers" == *" ubuntu "* ]]; then
    family_name="debian"
  elif [[ "$identifiers" == *" fedora "* ]]; then
    family_name="fedora"
  else
    return 1
  fi

  printf -v "$family_result_name" '%s' "$family_name"
  printf -v "$name_result_name" '%s' "${PRETTY_NAME:-$ID}"
}

# Detects a supported system family and returns its display name by reference.
environment_detect() {
  local family_result_name="$1"
  local name_result_name="$2"
  local family=""
  local name=""

  case "${OSTYPE:-}" in
    linux*)
      _environment_detect_linux family name || return 1
      ;;
    darwin*)
      family="macos"
      name="$(sw_vers -productName 2>/dev/null || printf 'macOS')"
      name+=" $(sw_vers -productVersion 2>/dev/null)"
      ;;
    *)
      return 1
      ;;
  esac

  printf -v "$family_result_name" '%s' "$family"
  printf -v "$name_result_name" '%s' "${name%% }"
}
