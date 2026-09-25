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
  herdr superfile neovim btop lazygit fastfetch zip zoxide fzf eza \
  stow git git-lfs

package_group brew_cask fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font

# Optional packages. A group is a plain list; a category is a labeled group of
# groups that the checkbox list renders as one section.
package_group brew toolchains \
  go nvm rustup uv sdkman-cli zig bun \
  cmake ninja tio

package_group brew shell_addons \
  tmux zellij yazi nvtop lazyjournal lazydocker mailsy taproom

package_group brew media_tools \
  yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full

package_group brew cli_harness \
  opencode hermes-agent openclaw

package_category brew dev_tools "Dev tools" toolchains
package_category brew terminal "Terminal" shell_addons
package_category brew media "Media" media_tools
package_category brew harness "CLI Harness" cli_harness
