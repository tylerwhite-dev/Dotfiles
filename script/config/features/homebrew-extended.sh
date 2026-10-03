#!/usr/bin/env bash

package_group brew toolchains \
  go nvm rustup uv sdkman-cli zig bun \
  cmake ninja tio

package_group brew shell_addons \
  lazygit lazyjournal lazydocker nvtop btop macmon taproom tmux zellij yazi mailsy

package_group brew media_tools \
  yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full

package_group brew cli_harness \
  opencode hermes-agent openclaw

package_category brew dev_tools "Dev tools" toolchains
package_category brew terminal "Terminal" shell_addons
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
  brew dev_tools \
  brew terminal \
  brew media \
  brew harness
message_define procedure.homebrew_extended.question \
  "Select the extended Homebrew packages to install?"
message_define procedure.homebrew_extended.label \
  "Install the extended Homebrew package set"
message_define procedure.homebrew_extended.description \
  "An additional tap will be added when needed. Select the packages to install:"
