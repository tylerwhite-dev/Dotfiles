#!/usr/bin/env bash

package_group brew_cask internet \
  firefox google-chrome librewolf zen ungoogled-chromium tor-browser \
  telegram whatsapp discord slack zoom \
  qbittorrent amneziavpn
package_group brew_cask work_media \
  obsidian libreoffice \
  bitwarden veracrypt \
  iina vlc spotify
package_group brew_cask create \
  figma inkscape blender \
  audacity obs
package_group brew_cask development \
  zed visual-studio-code vscodium \
  android-studio intellij-idea qt-creator \
  iterm2 ghostty cmux warp wezterm \
  docker-desktop hermes-desktop lm-studio
package_group brew_cask system \
  raycast maccy rectangle alt-tab jordanbaird-ice \
  betterdisplay mos linearmouse karabiner-elements hammerspoon \
  stats coconutbattery appcleaner \
  macfuse balenaetcher raspberry-pi-imager utm
package_group brew_cask games \
  steam playcover-community

package_category brew_cask internet_apps "Internet" internet
package_category brew_cask work_apps "Work & Media" work_media
package_category brew_cask create_apps "create" create
package_category brew_cask developer_apps "Dev tools" development
package_category brew_cask system_apps "System" system
package_category brew_cask gaming "Games" games

message_define status.cask_admin_prompt \
  "Installing selected casks. Enter your administrator password in the terminal or macOS dialog if prompted."

# Reports which of the given casks Homebrew already has installed.
homebrew_casks_installed_packages() {
  executor_brew_installed "$1" cask "${@:2}"
}

# Checks Homebrew before the direct-input cask installation phase.
action_prepare_homebrew_casks() {
  local brew_bin
  brew_bin="$(executor_brew_bin)"
  if [[ ! -x "$brew_bin" ]]; then
    error_report error.homebrew_missing "$brew_bin"
    return 1
  fi
  executor_run "$brew_bin" --version
}

# Runs in the parent shell so Homebrew and macOS can display password prompts.
action_install_homebrew_casks() {
  local -a selected=()
  workflow_selected_packages selected homebrew_casks || return
  ((${#selected[@]} > 0)) || return 0

  status_report status.cask_admin_prompt
  HOMEBREW_NO_INSTALL_UPGRADE=1 \
    executor_brew install --cask "${selected[@]}"
}

procedure_define homebrew_casks
procedure_handler homebrew_casks action_prepare_homebrew_casks
procedure_finish_handler homebrew_casks action_install_homebrew_casks
procedure_platforms homebrew_casks macos
procedure_requires homebrew_casks homebrew
procedure_selectable homebrew_casks
procedure_installed_probe homebrew_casks homebrew_casks_installed_packages
procedure_packages homebrew_casks \
  brew_cask internet_apps \
  brew_cask work_apps \
  brew_cask create_apps \
  brew_cask developer_apps \
  brew_cask system_apps \
  brew_cask gaming
message_define procedure.homebrew_casks.question \
  "Select macOS applications to install as Homebrew casks?"
message_define procedure.homebrew_casks.label \
  "Install selected Homebrew casks"
message_define procedure.homebrew_casks.description \
  "Some casks may request administrator access during installation."
