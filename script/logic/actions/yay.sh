#!/usr/bin/env bash

# Installs yay prerequisites, updates or clones its AUR checkout, and builds it.
action_install_yay() {
  local platform="$1"
  local user_home="${HOME:-}"
  local build_dir
  local -a packages=()

  if [[ -z "$user_home" ]]; then
    error_report error.home_unknown
    return 1
  fi
  build_dir="${user_home}/.cache/yay-build"

  if command -v yay >/dev/null 2>&1; then
    status_report status.yay_installed
    return 0
  fi

  catalog_packages packages yay "$platform" native || return
  executor_require pacman || return
  executor_retry_as_root \
    "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
    pacman -Syu --needed --noconfirm "${packages[@]}" || return
  executor_require git || return
  executor_require makepkg || return

  if [[ -d "${build_dir}/.git" ]]; then
    executor_retry \
      "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
      git -C "$build_dir" pull --ff-only || return
  else
    executor_run mkdir -p -- "$(dirname -- "$build_dir")" || return
    executor_retry \
      "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
      git clone https://aur.archlinux.org/yay.git "$build_dir" || return
  fi

  executor_run bash -c \
    'cd -- "$1" && exec makepkg --clean --cleanbuild --install --needed --noconfirm' \
    bash "$build_dir" || return

  if ! command -v yay >/dev/null 2>&1; then
    error_report error.yay_missing
    return 1
  fi
}
