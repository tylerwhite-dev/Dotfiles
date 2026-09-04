#!/usr/bin/env bash

execution_install_native_packages() {
  steps_load_step_packages native_packages "$distribution_family" native || return

  case "$distribution_family" in
    arch)
      execution_require_command pacman || return
      execution_retry_as_root 4 15 \
        pacman -Syu --needed --noconfirm "${STEPS_PACKAGES[@]}"
      ;;
    debian)
      execution_require_command apt-get || return
      execution_retry_as_root 4 15 apt-get update || return
      execution_retry_as_root 4 15 apt-get install -y "${STEPS_PACKAGES[@]}"
      ;;
    fedora)
      execution_require_command dnf || return
      execution_retry_as_root 4 15 \
        dnf install -y --refresh "${STEPS_PACKAGES[@]}"
      ;;
    *)
      ui_print_error "Native package installation is not implemented for: ${distribution_family}"
      return 1
      ;;
  esac
}
