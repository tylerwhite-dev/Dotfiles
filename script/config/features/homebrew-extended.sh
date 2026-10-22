#!/usr/bin/env bash

package_group brew shell_tools \
  starship zoxide fzf eza \
  zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch \
  taproom herdr tmux zellij

package_group brew util_tools \
  lazygit lazyjournal lazydocker mailsy tio \
  yazi superfile zip stow \
  nvtop btop macmon

package_group brew dev_tooling \
  go nvm rustup uv sdkman-cli zig bun \
  cmake ninja neovim fresh-editor

package_group brew media_tools \
  yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full

package_group brew cli_harness \
  opencode hermes-agent openclaw

package_category brew shell "Shell" shell_tools
package_category brew utils "Utils" util_tools
package_category brew dev_tools "Dev tools" dev_tooling
package_category brew media "Media" media_tools
package_category brew harness "CLI Harness" cli_harness

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

procedure_define homebrew_extended
procedure_handler homebrew_extended action_install_homebrew_extended
procedure_platforms homebrew_extended arch debian fedora macos
procedure_requires homebrew_extended homebrew
procedure_selectable homebrew_extended
procedure_packages homebrew_extended \
  brew shell \
  brew utils \
  brew dev_tools \
  brew harness \
  brew media
message_define procedure.homebrew_extended.question \
  "Select the extended Homebrew packages to install?"
message_define procedure.homebrew_extended.label \
  "Install the extended Homebrew package set"
message_define procedure.homebrew_extended.description \
  "An additional tap will be added when needed. Select the packages to install:"
