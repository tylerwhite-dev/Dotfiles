#!/usr/bin/env bash

# Installs the platform-specific native package group with its package manager.
action_install_native_packages() {
  local platform="$1"
  local -a packages=()

  catalog_packages packages native_packages "$platform" native || return

  case "$platform" in
    arch)
      executor_require pacman || return
      executor_retry_as_root \
        "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        pacman -Syu --needed --noconfirm "${packages[@]}"
      ;;
    debian)
      executor_require apt-get || return
      executor_retry_as_root \
        "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        apt-get update || return
      executor_retry_as_root \
        "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        apt-get install -y "${packages[@]}"
      ;;
    fedora)
      executor_require dnf || return
      executor_retry_as_root \
        "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        dnf install -y --refresh "${packages[@]}"
      ;;
    *)
      error_report error.native_packages_unsupported "$platform"
      return 1
      ;;
  esac
}
