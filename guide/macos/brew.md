# installation

[brew](https://brew.sh)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

The setup script at the repository root can run the installation and the
package groups below for you; see [`deploy/README.md`](../../deploy/README.md).

# packages

## casks

```bash
brew install --cask firefox google-chrome telegram qbittorrent amneziavpn brave-browser microsoft-edge chromium librewolf arc zen ungoogled-chromium tor-browser discord slack zoom whatsapp microsoft-teams signal bluebubbles wechat thunderbird obsidian libreoffice iina bitwarden veracrypt vlc spotify blender inkscape obs gimp figma audacity handbrake-app zed visual-studio-code vscodium ghostty hermes-desktop docker-desktop lm-studio android-studio intellij-idea qt-creator iterm2 warp cmux kitty wezterm alacritty termius wave tabby cursor sublime-text emacs-app intellij-idea-ce coteditor utm appcleaner betterdisplay coconutbattery macfuse mos raycast balenaetcher raspberry-pi-imager stats rectangle maccy alt-tab karabiner-elements jordanbaird-ice hammerspoon linearmouse playcover-community steam
```

## utilities

```bash
brew install bash-completion btop cbonsai eza fastfetch ffmpeg-full git-lfs htop imagemagick-full jq lazygit macmon mailsy neovim nvtop pfetch-rs starship stow superfile tio tmux tree yazi yt-dlp zip zoxide fzf zsh-autosuggestions zsh-syntax-highlighting
```

## developer

```bash
brew install cmake go nvm qt opencode rustup uv zig
```

## fonts

```bash
brew install font-hack-nerd-font font-jetbrains-mono-nerd-font
```

# configurations

## starship

( contained in [`zshrc macos`](../../zsh_mac/.zshrc) )

add to file ~/.zshrc (contained in `.zshrc macos`)

```bash
eval "$(starship init bash)"
```
