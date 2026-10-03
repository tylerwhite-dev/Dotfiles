#!/usr/bin/env bash

package_group native yay_prerequisites \
  go

message_define error.home_unknown \
  "Could not determine the user's home directory."

message_define error.yay_missing \
  "The yay build completed, but yay was not found in PATH."

message_define error.yay_package_missing \
  "The built yay package was not found: %s"

message_define status.yay_installed \
  "yay is already installed."

message_define status.yay_install_password \
  "Build complete. Installing yay with pacman. Enter your sudo password if prompted."

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
    'cd -- "$1" && exec makepkg --clean --cleanbuild --force' \
    bash "$build_dir"
}

# Installs the completed yay package with an unobscured sudo prompt.
action_install_yay_package() {
  local user_home="${HOME:-}"
  local build_dir
  local package_list
  local package_file
  local -a package_files=()

  if command -v yay >/dev/null 2>&1; then
    return 0
  fi
  if [[ -z "$user_home" ]]; then
    error_report error.home_unknown
    return 1
  fi
  build_dir="${user_home}/.cache/yay-build"

  (
    cd -- "$build_dir" || return
    package_list="$(makepkg --packagelist)" || return
    if [[ -z "$package_list" ]]; then
      error_report error.yay_package_missing "$build_dir"
      return 1
    fi
    mapfile -t package_files <<< "$package_list"
    for package_file in "${package_files[@]}"; do
      if [[ ! -f "$package_file" ]]; then
        error_report error.yay_package_missing "$package_file"
        return 1
      fi
    done

    status_report status.yay_install_password
    executor_run_as_root pacman -U --needed --noconfirm -- "${package_files[@]}"
  ) || return

  if ! command -v yay >/dev/null 2>&1; then
    error_report error.yay_missing
    return 1
  fi
}

procedure_define yay
procedure_handler yay action_install_yay
procedure_finish_handler yay action_install_yay_package
procedure_platforms yay arch
procedure_requires_root yay arch
procedure_packages yay native yay_prerequisites
message_define procedure.yay.question "Install yay?"
message_define procedure.yay.label "Install yay"
message_define procedure.yay.description \
  "Build dependencies are installed first. Then yay is built from the AUR and installed with sudo, which may ask for your password."
