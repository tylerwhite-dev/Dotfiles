# installation

[website](https://brew.sh)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

reboot and check (make sure you have brew in your path)
```
which brew
```

# user access
To access homebrew packages, add its bin directory to PATH:
```bash
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
```

# formulae

## main
```
zsh-autosuggestions zsh-syntax-highlighting yazi starship tmux neovim fastfetch pfetch-rs btop yt-dlp nvtop zoxide eza lazygit
```

## tap
```
oven-sh/bun
```

## fonts
```
font-jetbrains-mono-nerd-font font-hack-nerd-font
```

## optional
```
opencode charmbracelet/tap/crush qwen-code
llvm cmake go nvm rustup uv zig bun 
ffmpeg-full superfile htop tree mailsy imagemagick-full gromgit/brewtils/taproom file-formula 
```
