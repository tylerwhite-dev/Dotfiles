# installation

[brew](https://brew.sh)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

# packages

## casks
```
--cask telegram obsidian google-chrome betterdisplay transmission qbittorrent balenaetcher steam iina mos playcover-community utm veracrypt macfuse appcleaner logi-options+ amneziavpn lm-studio 

visual-studio-code vscodium docker-desktop virtualbox android-studio 
```

## utilities
```
zsh-autosuggestions zsh-syntax-highlighting superfile yazi file-formula starship tmux fastfetch btop macmon tree git-lfs yt-dlp nvtop stow mailsy imagemagick-full gromgit/brewtils/taproom zoxide eza pfetch-rs ffmpeg
```

## developer
```
lazygit neovim rustup cmake nvm go uv qt-creator qt qwen-code charmbracelet/tap/crush anomalyco/tap/opencode
```

## fonts
```
font-jetbrains-mono-nerd-font font-hack-nerd-font 
```

# configurations

## starship
( contained in [`zshrc macos`](../../zsh_mac/.zshrc) )

add to file ~/.zshrc (contained in `.zshrc macos`)
```bash
eval "$(starship init bash)"
```

## rustup
```
rustup install stable

rustup default stable

rustc -V
cargo -V
rustup show
```