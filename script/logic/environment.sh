#!/usr/bin/env bash

# Detects a supported Linux family and returns its display name by reference.
environment_detect() {
  local family_result_name="$1"
  local name_result_name="$2"

  if [[ "${OSTYPE:-}" != linux* || ! -r /etc/os-release ]]; then
    return 1
  fi

  local ID=""
  local ID_LIKE=""
  local PRETTY_NAME=""
  local family=""

  # /etc/os-release contains shell-compatible variable assignments.
  # shellcheck disable=SC1091
  source /etc/os-release

  local identifiers=" ${ID,,} ${ID_LIKE,,} "
  if [[ "$identifiers" == *" arch "* ]]; then
    family="arch"
  elif [[ "$identifiers" == *" debian "* || "$identifiers" == *" ubuntu "* ]]; then
    family="debian"
  elif [[ "$identifiers" == *" fedora "* ]]; then
    family="fedora"
  else
    return 1
  fi

  printf -v "$family_result_name" '%s' "$family"
  printf -v "$name_result_name" '%s' "${PRETTY_NAME:-$ID}"
}
