#!/usr/bin/env bash

package_group brew extensions \
  starship zsh-autosuggestions zsh-syntax-highlighting \
  pfetch-rs fastfetch

package_group brew cli_tools \
  herdr superfile neovim zip zoxide fzf eza stow

package_group brew_cask fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font

message_define status.homebrew_admin_prompt \
  "Installing Homebrew requires administrator access. Enter your sudo password if prompted."

# Downloads and runs the Homebrew installer when Homebrew is absent.
# On macOS developer tools and administrator access must be ready first.
action_install_homebrew_binary() {
  local installer
  local setup_dir=0

  if [[ "${OSTYPE:-}" == darwin* ]]; then
    if ! executor_macos_developer_tools_ready; then
      error_report error.macos_clt_missing
      return 1
    fi
    # Normal runs authenticate in process_run; --add-optionals calls us directly.
    if ! sudo -n -v >/dev/null 2>&1; then
      status_report status.homebrew_admin_prompt
      executor_prepare_privilege || return
    fi
  else
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
    action_install_homebrew_binary || return
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

procedure_define homebrew
procedure_handler homebrew action_install_homebrew
procedure_platforms homebrew arch debian fedora macos
procedure_requires_root homebrew arch debian fedora macos
procedure_packages homebrew \
  brew extensions \
  brew cli_tools \
  brew_cask fonts
message_define procedure.homebrew.question \
  "Install Homebrew, core CLI tools, and fonts?"
message_define procedure.homebrew.label \
  "Install Homebrew, core CLI tools, and fonts"
message_define procedure.homebrew.description \
  "Homebrew will be installed, followed by these packages:"
