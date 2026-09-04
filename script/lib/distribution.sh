#!/usr/bin/env bash

distribution_family=""
distribution_name=""

distribution_detect() {
  if [[ "${OSTYPE:-}" != linux* || ! -r /etc/os-release ]]; then
    return 1
  fi

  local ID=""
  local ID_LIKE=""
  local PRETTY_NAME=""

  # /etc/os-release contains shell-compatible variable assignments.
  # shellcheck disable=SC1091
  source /etc/os-release

  local identifiers=" ${ID,,} ${ID_LIKE,,} "

  if [[ "$identifiers" == *" arch "* ]]; then
    distribution_family="arch"
  elif [[ "$identifiers" == *" debian "* || "$identifiers" == *" ubuntu "* ]]; then
    distribution_family="debian"
  elif [[ "$identifiers" == *" fedora "* ]]; then
    distribution_family="fedora"
  else
    return 1
  fi

  distribution_name="${PRETTY_NAME:-$ID}"
}

distribution_require_supported() {
  if ! distribution_detect; then
    ui_print_error "The distribution could not be detected or is not supported."
    printf 'Supported distributions: Arch Linux, Debian, Ubuntu, and Fedora.\n'
    return 1
  fi

  ui_print_success "Detected distribution: ${distribution_name}"
}
