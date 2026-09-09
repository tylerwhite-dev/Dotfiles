#!/usr/bin/env bash

# Downloads and runs the Linux Homebrew installer when Homebrew is absent.
_action_install_homebrew_binary() {
  local installer

  installer="$(executor_temp_file)" || return
  executor_run_as_root mkdir -p /home/linuxbrew || return
  executor_run_as_root chown "$(id -u):$(id -g)" /home/linuxbrew || return
  executor_download \
    https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
    "$installer" || return

  if ! executor_run env \
    NONINTERACTIVE=1 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    /bin/bash "$installer"; then
    executor_is_dry_run || rm -f -- "$installer"
    return 1
  fi

  executor_run rm -f -- "$installer"
}

# Installs Homebrew, core formulae, and font casks for the current platform.
action_install_homebrew() {
  local platform="$1"
  local -a packages=()

  if executor_is_dry_run || [[ ! -x "$SETUP_BREW_BIN" ]]; then
    _action_install_homebrew_binary || return
  fi

  if ! executor_is_dry_run && [[ ! -x "$SETUP_BREW_BIN" ]]; then
    error_report error.homebrew_missing "$SETUP_BREW_BIN"
    return 1
  fi

  executor_run "$SETUP_BREW_BIN" --version || return
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
