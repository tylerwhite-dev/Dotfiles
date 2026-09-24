#!/usr/bin/env bash

# Applies the repository's Stow packages after checking its marker file.
action_apply_dotfiles() {
  local platform="$1"
  local repository_dir="$2"
  local -a packages=()
  local package

  if [[ "$platform" == "macos" ]]; then
    packages=(. zsh_common wallpaper zsh_mac)
  else
    packages=(. zsh_common wallpaper zsh_linux)
  fi

  if [[ ! -f "${repository_dir}/.stow-local-ignore" ]]; then
    error_report error.repository_marker_missing \
      "${repository_dir}/.stow-local-ignore"
    return 1
  fi

  executor_require stow || return

  (
    cd -- "$repository_dir" || return
    for package in "${packages[@]}"; do
      executor_run stow --no-folding "$package" || return
    done
  )
}
