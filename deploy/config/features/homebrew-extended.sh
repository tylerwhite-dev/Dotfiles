#!/usr/bin/env bash

package_group brew shell_tools \
  starship zoxide fzf eza \
  zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch \
  taproom herdr tmux zellij

# Supplies defaults when the earlier Zsh procedure was selected.
homebrew_extended_package_defaults() {
  local -n __homebrew_defaults_result="$1"
  local zsh_selection
  __homebrew_defaults_result=()
  workflow_selection zsh_selection zsh_default
  if [[ "$zsh_selection" == yes ]]; then
    __homebrew_defaults_result=(
      starship zsh-autosuggestions zsh-syntax-highlighting pfetch-rs zoxide
      herdr stow
    )
  fi
}

package_alias brew zsh-autosuggestions "zsh suggestions"
package_alias brew zsh-syntax-highlighting "zsh syntax"

package_group brew util_tools \
  lazygit lazyjournal lazydocker mailsy tio \
  yazi superfile zip stow \
  nvtop btop macmon \
  typtea typioca

package_group brew dev_tooling \
  fresh-editor neovim podman \
  nvm rustup uv sdkman-cli go qt bun \
  cmake ninja \
  openspec mise hyperfine

package_requires brew sdkman-cli NATIVE_BUILD_TOOLS

package_group brew media_tools \
  yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full

package_group brew cli_harness \
  codex claude-code \
  opencode hermes-agent kimi-code antigravity-cli openclaw

package_category brew shell "Shell" shell_tools
package_category brew utils "Utils" util_tools
package_category brew dev_tools "Dev tools" dev_tooling
package_category brew media "Media" media_tools
package_category brew harness "CLI Harness" cli_harness

# Reports which of the given packages Homebrew already has installed.
homebrew_extended_installed_packages() {
  executor_brew_installed "$1" all "${@:2}"
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

  HOMEBREW_NO_INSTALL_UPGRADE=1 \
    executor_brew install "${selected[@]}"
}

procedure_define homebrew_extended
procedure_handler homebrew_extended action_install_homebrew_extended
procedure_platforms homebrew_extended arch debian fedora macos
procedure_requires homebrew_extended homebrew
procedure_selectable homebrew_extended
procedure_installed_probe homebrew_extended homebrew_extended_installed_packages
procedure_defaults_handler homebrew_extended homebrew_extended_package_defaults
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
