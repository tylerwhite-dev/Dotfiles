#!/usr/bin/env bash

# Add a feature file, then put its procedure ID in this queue.
# Move an ID to reorder it; remove or comment it out to disable the procedure.
# Requirements must precede their dependants. An omitted requirement also
# disables its dependants. An empty queue enables no procedures.
setup_procedure_order=(
  native_packages
  yay
  zsh_default
  macos_command_line_tools
  macos_finder
  macos_spaces
  homebrew
  homebrew_extended
  flatpak_apps
  homebrew_casks
  dotfiles
)
procedure_order "${setup_procedure_order[@]}"
unset setup_procedure_order
