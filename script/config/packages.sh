#!/usr/bin/env bash

package_group native arch \
  sudo git git-lfs curl openssh zsh nano stow file wl-clipboard

package_group native debian \
  sudo git git-lfs curl ssh zsh nala nano stow file wl-clipboard build-essential

package_group native fedora \
  sudo git git-lfs curl openssh-clients zsh nano stow file wl-clipboard gcc

package_group native yay_prerequisites \
  base-devel git go

package_group brew extensions \
  starship zsh-autosuggestions zsh-syntax-highlighting tmux pfetch-rs zoxide fzf eza

package_group brew cli_tools \
  yazi neovim btop nvtop opencode lazygit fastfetch zip

package_group brew_cask fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font

package_group brew optional \
  taproom superfile tio go nvm rustup uv sdkman-cli yt-dlp ffmpeg-full \
  imagemagick-full mailsy
