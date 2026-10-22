#!/usr/bin/env bash

package_group brew core_cli_tools_extensions \
  starship zsh-autosuggestions zsh-syntax-highlighting \
  pfetch-rs

package_group brew core_cli_tools_packages \
  herdr superfile zip zoxide fzf eza stow

# Installs the core formulae using the prepared Homebrew executable.
action_install_core_cli_tools() {
  local platform="$1"
  local -a packages=()

  catalog_packages packages core_cli_tools "$platform" brew || return
  executor_brew install "${packages[@]}"
}

procedure_define core_cli_tools
procedure_handler core_cli_tools action_install_core_cli_tools
procedure_platforms core_cli_tools arch debian fedora macos
procedure_requires core_cli_tools homebrew
procedure_packages core_cli_tools \
  brew core_cli_tools_extensions \
  brew core_cli_tools_packages
message_define procedure.core_cli_tools.question \
  "Install core CLI tools?"
message_define procedure.core_cli_tools.label \
  "Install core CLI tools"
message_define procedure.core_cli_tools.description \
  "These core CLI tools and shell extensions will be installed using Homebrew:"
