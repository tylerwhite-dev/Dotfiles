#!/usr/bin/env bash

package_group native arch \
  git git-lfs curl openssh zsh file wl-clipboard

package_group native debian \
  git git-lfs curl ssh zsh nala file wl-clipboard

package_group native fedora \
  git git-lfs curl openssh-clients zsh file wl-clipboard

# Installs the platform-specific native package group with its package manager.
action_install_native_packages() {
  local platform="$1"
  local -a packages=()

  catalog_packages packages native_packages "$platform" native || return

  executor_install_native_items "$platform" package "${packages[@]}"
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
