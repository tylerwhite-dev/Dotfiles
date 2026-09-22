#!/usr/bin/env bash

package_group native arch \
  sudo git git-lfs curl openssh zsh nano stow file wl-clipboard

package_group native debian \
  sudo git git-lfs curl ssh zsh nala nano stow file wl-clipboard build-essential

package_group native fedora \
  sudo git git-lfs curl openssh-clients zsh nano stow file wl-clipboard gcc

package_group native yay_prerequisites \
  base-devel go

package_group brew extensions \
  starship zsh-autosuggestions zsh-syntax-highlighting pfetch-rs

package_group brew cli_tools \
  herdr superfile neovim btop opencode lazygit fastfetch zip zoxide fzf eza

package_group brew_cask fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font

package_group brew optional \
  go nvm rustup uv sdkman-cli \
  lazydocker nvtop tio \
  yt-dlp ffmpeg ffmpeg-full \
  imagemagick imagemagick-full \
  taproom tmux yazi mailsy
