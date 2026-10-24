#!/usr/bin/env bash

package_group brew_cask homebrew_fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font \
  font-zed-mono-nerd-font font-meslo-lg-nerd-font \
  font-adwaita-mono-nerd-font font-commit-mono-nerd-font \
  font-fira-code-nerd-font 
  

# Installs font casks after the core Homebrew procedure.
action_install_homebrew_fonts() {
  local platform="$1"
  local -a packages=()

  catalog_packages packages homebrew_fonts "$platform" brew_cask || return
  executor_brew install --cask "${packages[@]}"
}

procedure_define homebrew_fonts
procedure_handler homebrew_fonts action_install_homebrew_fonts
procedure_platforms homebrew_fonts arch debian fedora macos
procedure_requires homebrew_fonts homebrew
procedure_packages homebrew_fonts brew_cask homebrew_fonts
message_define procedure.homebrew_fonts.question \
  "Install Nerd Fonts using Homebrew?"
message_define procedure.homebrew_fonts.label \
  "Install Nerd Fonts"
message_define procedure.homebrew_fonts.description \
  "JetBrains Mono and Hack Nerd Fonts will be installed as Homebrew casks."
