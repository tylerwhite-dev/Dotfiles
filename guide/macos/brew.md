# installation

[brew](https://brew.sh)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

# packages

## casks

```bash
brew install --cask amneziavpn appcleaner balenaetcher betterdisplay bitwarden coconutbattery docker-desktop firefox ghostty google-chrome iina libreoffice lm-studio macfuse mos obsidian playcover-community qbittorrent raspberry-pi-imager raycast steam telegram utm veracrypt zed
```

## utilities

```bash
brew install bash-completion btop cbonsai eza fastfetch ffmpeg-full fzf git-lfs htop imagemagick-full jq lazygit macmon mailsy neovim nvtop pfetch-rs starship stow superfile tio tmux tree yazi yt-dlp zip zoxide zsh-autosuggestions zsh-syntax-highlighting
```

## developer

```bash
brew install android-studio cmake go intellij-idea-ce nvm qt qt-creator vscodium opencode rustup uv zig
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
