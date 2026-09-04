#!/usr/bin/env bash

execution_apply_dotfiles() {
  local packages=(. zsh_common wallpaper zsh_linux)
  local package

  if [[ ! -f "${execution_repository_dir}/.stow-local-ignore" ]]; then
    ui_print_error "Repository marker not found: ${execution_repository_dir}/.stow-local-ignore"
    return 1
  fi

  execution_require_command stow || return

  (
    cd -- "$execution_repository_dir" || return

    for package in "${packages[@]}"; do
      execution_run stow --no-folding "$package" || return
    done
  )
}
