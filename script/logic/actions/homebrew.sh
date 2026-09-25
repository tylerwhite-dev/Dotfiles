#!/usr/bin/env bash

# Downloads and runs the Homebrew installer when Homebrew is absent.
# On macOS no system directories or root privileges are needed.
_action_install_homebrew_binary() {
  local installer
  local setup_dir=0

  if [[ "${OSTYPE:-}" != darwin* ]]; then
    setup_dir=1
  fi

  installer="$(executor_temp_file)" || return
  if ((setup_dir)); then
    executor_run_as_root mkdir -p /home/linuxbrew || return
    executor_run_as_root chown "$(id -u):$(id -g)" /home/linuxbrew || return
  fi
  executor_download \
    https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
    "$installer" || return

  if ! executor_run env \
    NONINTERACTIVE=1 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    /bin/bash "$installer"; then
    rm -f -- "$installer"
    return 1
  fi

  executor_run rm -f -- "$installer"
}

# Installs Homebrew, core formulae, and font casks for the current platform.
action_install_homebrew() {
  local platform="$1"
  local -a packages=()
  local brew_bin

  brew_bin="$(executor_brew_bin)"

  if [[ ! -x "$brew_bin" ]]; then
    _action_install_homebrew_binary || return
  fi

  if [[ ! -x "$brew_bin" ]]; then
    error_report error.homebrew_missing "$brew_bin"
    return 1
  fi

  executor_run "$brew_bin" --version || return
  catalog_packages packages homebrew "$platform" brew || return
  executor_brew install "${packages[@]}" || return
  catalog_packages packages homebrew "$platform" brew_cask || return
  executor_brew install --cask "${packages[@]}"
}

# Installs the user-selected extended Homebrew packages.
action_install_homebrew_extended() {
  local platform="$1"
  local -a selected=()

  workflow_selected_packages selected homebrew_extended || return
  if ((${#selected[@]} == 0)); then
    return 0
  fi

  if [[ " ${selected[*]} " == *" sdkman-cli "* ]]; then
    executor_brew tap sdkman/tap || return
    executor_brew trust --tap sdkman/tap || return
  fi

  executor_brew install "${selected[@]}"
}
