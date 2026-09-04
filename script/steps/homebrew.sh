#!/usr/bin/env bash

execution_install_homebrew() {
  local installer

  if [[ "$execution_dry_run" == "1" || ! -x "$execution_brew_bin" ]]; then
    installer="$(execution_temp_file)" || return

    execution_run_as_root mkdir -p /home/linuxbrew || return
    execution_run_as_root chown "$(id -u):$(id -g)" /home/linuxbrew || return
    execution_download \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
      "$installer" || return

    if ! execution_run env \
      NONINTERACTIVE=1 \
      HOMEBREW_NO_ANALYTICS=1 \
      HOMEBREW_NO_AUTO_UPDATE=1 \
      /bin/bash "$installer"; then
      [[ "$execution_dry_run" == "1" ]] || rm -f -- "$installer"
      return 1
    fi

    execution_run rm -f -- "$installer" || return
  fi

  if [[ "$execution_dry_run" != "1" && ! -x "$execution_brew_bin" ]]; then
    ui_print_error "Homebrew was not installed at ${execution_brew_bin}"
    return 1
  fi

  execution_run "$execution_brew_bin" --version || return
  steps_load_step_packages homebrew "$distribution_family" brew || return
  execution_brew install "${STEPS_PACKAGES[@]}" || return
  steps_load_step_packages homebrew "$distribution_family" brew_cask || return
  execution_brew install --cask "${STEPS_PACKAGES[@]}"
}

execution_install_homebrew_extended() {
  local tap

  steps_load_step_packages homebrew_extended "$distribution_family" brew_tap || return

  for tap in "${STEPS_PACKAGES[@]}"; do
    execution_brew tap "$tap" || return
    execution_brew trust --tap "$tap" || return
  done

  steps_load_step_packages homebrew_extended "$distribution_family" brew || return
  execution_brew install "${STEPS_PACKAGES[@]}"
}
