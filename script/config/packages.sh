#!/usr/bin/env bash

package_group native arch \
  git git-lfs curl openssh zsh file wl-clipboard base-devel

package_group native debian \
  git git-lfs curl ssh zsh nala file wl-clipboard build-essential

package_group native fedora \
  git git-lfs curl openssh-clients zsh file wl-clipboard gcc

package_group native yay_prerequisites \
  go

package_group brew extensions \
  starship zsh-autosuggestions zsh-syntax-highlighting pfetch-rs

package_group brew cli_tools \
  herdr superfile neovim btop opencode lazygit fastfetch zip zoxide fzf eza \
  stow git git-lfs

package_group brew_cask fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font

package_group brew optional \
  go nvm rustup uv sdkman-cli \
  lazydocker nvtop tio \
  yt-dlp ffmpeg ffmpeg-full \
  imagemagick imagemagick-full \
  taproom tmux yazi mailsy
