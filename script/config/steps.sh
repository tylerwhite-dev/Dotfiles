#!/usr/bin/env bash

# Native repository packages

package_group native arch \
  sudo \
  git \
  git-lfs \
  curl \
  openssh \
  zsh \
  nano \
  stow \
  file \
  wl-clipboard

package_group native debian \
  sudo \
  git \
  git-lfs \
  curl \
  ssh \
  zsh \
  nala \
  nano \
  stow \
  file \
  wl-clipboard \
  build-essential

package_group native fedora \
  sudo \
  git \
  git-lfs \
  curl \
  openssh-clients \
  zsh \
  nano \
  stow \
  file \
  wl-clipboard \
  gcc

package_group native yay_prerequisites \
  base-devel \
  git \
  go

# Homebrew packages

package_group brew extensions \
  starship \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  tmux \
  pfetch-rs \
  zoxide \
  fzf \
  eza

package_group brew cli_tools \
  yazi \
  neovim \
  btop \
  nvtop \
  opencode \
  lazygit \
  fastfetch \
  zip

package_group brew_cask fonts \
  font-jetbrains-mono-nerd-font \
  font-hack-nerd-font

package_group brew optional \
  taproom \
  superfile \
  tio \
  go \
  nvm \
  rustup \
  uv \
  sdkman-cli \
  yt-dlp \
  ffmpeg-full \
  imagemagick-full \
  mailsy

package_group brew_tap optional \
  sdkman/tap

# Steps: id, question, comment, execution function, platforms, optional requirement.
# Each execution function lives in its own file under script/steps.

step \
  native_packages \
  "Install base system packages?" \
  "The following packages will be installed from the native repository:" \
  execution_install_native_packages \
  "arch debian fedora"

step_packages native_packages native @distribution

step \
  homebrew \
  "Install Homebrew, core CLI tools, and fonts?" \
  "Homebrew will be installed, followed by these packages:" \
  execution_install_homebrew \
  "arch debian fedora"

step_packages homebrew \
  brew extensions \
  brew cli_tools \
  brew_cask fonts

step \
  homebrew_extended \
  "Install the extended Homebrew package set?" \
  "An additional tap will be added, followed by these packages:" \
  execution_install_homebrew_extended \
  "arch debian fedora" \
  homebrew

step_packages homebrew_extended \
  brew_tap optional \
  brew optional

step \
  zsh_default \
  "Set Zsh as the default shell?" \
  "The current user's login shell will be changed to /bin/zsh." \
  execution_set_zsh_default \
  "arch debian fedora"

step \
  dotfiles \
  "Apply dotfiles, Zsh configuration, and wallpapers with GNU Stow?" \
  "GNU Stow will apply ., zsh_common, wallpaper, and zsh_linux with --no-folding from the Dotfiles directory." \
  execution_apply_dotfiles \
  "arch debian fedora"

step \
  yay \
  "Install yay?" \
  "The build dependencies will be installed first. Then yay will be built from the AUR and installed:" \
  execution_install_yay \
  "arch"

step_packages yay native yay_prerequisites
