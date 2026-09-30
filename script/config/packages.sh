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
  starship zsh-autosuggestions zsh-syntax-highlighting \
  pfetch-rs fastfetch

package_group brew cli_tools \
  herdr superfile neovim zip zoxide fzf eza stow

package_group brew_cask fonts \
  font-jetbrains-mono-nerd-font font-hack-nerd-font

# Optional packages. A group is a plain list; a category is a labeled group of
# groups that the checkbox list renders as one section.
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

# Optional macOS applications from guide/macos/brew.md.
package_group brew_cask internet \
  firefox google-chrome telegram qbittorrent amneziavpn
package_group brew_cask work_media \
  obsidian libreoffice iina bitwarden veracrypt
package_group brew_cask development \
  android-studio intellij-idea qt-creator vscodium \
  docker-desktop ghostty lm-studio zed
package_group brew_cask system \
  utm appcleaner betterdisplay coconutbattery macfuse mos raycast \
  balenaetcher raspberry-pi-imager
package_group brew_cask games \
  playcover-community steam

package_category brew_cask internet_apps "Internet" internet
package_category brew_cask work_apps "Work & Media" work_media
package_category brew_cask developer_apps "Dev tools" development
package_category brew_cask system_apps "System" system
package_category brew_cask gaming "Games" games
