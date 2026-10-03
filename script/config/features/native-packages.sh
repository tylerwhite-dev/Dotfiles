#!/usr/bin/env bash

package_group native arch \
  git git-lfs curl openssh zsh file wl-clipboard base-devel

package_group native debian \
  git git-lfs curl ssh zsh nala file wl-clipboard build-essential

package_group native fedora \
  git git-lfs curl openssh-clients zsh file wl-clipboard gcc

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
      executor_require apt || return
      executor_retry_as_root \
        "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        apt update || return
      executor_retry_as_root \
        "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        apt install -y "${packages[@]}"
      ;;
    fedora)
      executor_require dnf || return
      executor_run_as_root \
        dnf config-manager setopt fedora-cisco-openh264.enabled=0 || return
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

procedure_define native_packages
procedure_handler native_packages action_install_native_packages
procedure_platforms native_packages arch debian fedora
procedure_requires_root native_packages arch debian fedora
procedure_packages native_packages native @distribution
message_define procedure.native_packages.question "Install base system packages?"
message_define procedure.native_packages.label "Install base system packages"
message_define procedure.native_packages.description \
  "The following packages will be installed from the native repository:"
