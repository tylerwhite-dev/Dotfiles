#!/usr/bin/env bash

execution_install_yay() {
  local build_dir="${HOME}/.cache/yay-build"

  if [[ "$execution_dry_run" != "1" ]] && command -v yay >/dev/null 2>&1; then
    printf 'yay is already installed.\n'
    return 0
  fi

  steps_load_step_packages yay "$distribution_family" native || return
  execution_require_command pacman || return
  execution_retry_as_root 4 15 \
    pacman -Syu --needed --noconfirm "${STEPS_PACKAGES[@]}" || return
  execution_require_command git || return
  execution_require_command makepkg || return

  if [[ -d "${build_dir}/.git" ]]; then
    execution_retry 4 15 git -C "$build_dir" pull --ff-only || return
  else
    execution_run mkdir -p -- "$(dirname -- "$build_dir")" || return
    execution_retry 4 15 \
      git clone https://aur.archlinux.org/yay.git "$build_dir" || return
  fi

  execution_run bash -c \
    'cd -- "$1" && exec makepkg --clean --cleanbuild --install --needed --noconfirm' \
    bash "$build_dir" || return

  if [[ "$execution_dry_run" != "1" ]] && ! command -v yay >/dev/null 2>&1; then
    ui_print_error "The yay build completed, but yay was not found in PATH."
    return 1
  fi
}
