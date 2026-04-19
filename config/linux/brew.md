# installation

[website](https://brew.sh)
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

reboot and check (make sure you have brew in your path)
```
which brew
```

# user access
To access homebrew packages, add its bin directory to PATH:
```
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
```

# formulae

## main
```
zsh-autosuggestions zsh-syntax-highlighting yazi starship tmux neovim fastfetch pfetch-rs btop yt-dlp nvtop zoxide eza lazygit
```

## optional
```
brew tap oven-sh/bun
```

## fonts
```
font-jetbrains-mono-nerd-font font-hack-nerd-font
```

```
anomalyco/tap/opencode charmbracelet/tap/crush qwen-code
llvm cmake go nvm rustup uv zig bun 
ffmpeg-full superfile htop tree mailsy imagemagick-full gromgit/brewtils/taproom file-formula 
```
