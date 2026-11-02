#!/usr/bin/env bash

# Platform availability and queue order still come from the procedure catalog.
declare -Ag SETUP_SCENARIO_PROCEDURES=(
  [server]='native_packages zsh_default homebrew homebrew_extended dotfiles'
  [desktop]='native_packages yay zsh_default homebrew homebrew_fonts homebrew_extended flatpak_apps dotfiles'
  [wsl]='native_packages yay zsh_default homebrew homebrew_extended dotfiles'
  [mac]='macos_command_line_tools macos_finder macos_spaces homebrew homebrew_fonts homebrew_extended homebrew_casks dotfiles'
)
