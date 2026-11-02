#!/usr/bin/env bash

package_group brew_cask homebrew_fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font \
  font-zed-mono-nerd-font font-meslo-lg-nerd-font \
  font-adwaita-mono-nerd-font font-commit-mono-nerd-font \
  font-fira-code-nerd-font

package_category brew_cask all_fonts "All" homebrew_fonts

# Reports which font casks are already installed.
homebrew_fonts_installed_packages() {
  executor_brew_installed "$1" cask "${@:2}"
}

# Installs the selected font casks.
action_install_homebrew_fonts() {
  local -a packages=()

  workflow_selected_packages packages homebrew_fonts || return
  ((${#packages[@]})) || return 0
  HOMEBREW_NO_INSTALL_UPGRADE=1 executor_brew install --cask "${packages[@]}"
}

procedure_define homebrew_fonts
procedure_handler homebrew_fonts action_install_homebrew_fonts
procedure_platforms homebrew_fonts arch debian fedora macos
procedure_requires homebrew_fonts homebrew
procedure_selectable homebrew_fonts
procedure_installed_probe homebrew_fonts homebrew_fonts_installed_packages
procedure_packages homebrew_fonts brew_cask all_fonts
message_define procedure.homebrew_fonts.question \
  "Select Nerd Fonts to install using Homebrew:"
message_define procedure.homebrew_fonts.label \
  "Install Nerd Fonts"
message_define procedure.homebrew_fonts.description \
  "Select the Nerd Fonts to install as Homebrew casks."
