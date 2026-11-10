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

The deploy script offers these formulae for selection. When zsh is selected,
it preselects `starship`, `zsh-autosuggestions`, `zsh-syntax-highlighting`,
`pfetch-rs`, `zoxide`, `herdr`, and `stow`.

## shell
```
starship zoxide fzf eza zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch taproom herdr tmux zellij
```

## utils
```
lazygit lazyjournal lazydocker mailsy tio yazi superfile zip stow nvtop btop macmon typtea typioca
```

## dev tools
```
fresh-editor neovim mise nvm rustup uv sdkman-cli go qt zig bun cmake ninja
```

## media
```
yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full
```

## CLI harness
```
opencode hermes-agent codex claude-code antigravity-cli openclaw
```

## tap
```
sdkman/tap
```

The deploy script adds and trusts this tap when `sdkman-cli` is selected.

## fonts
These are installed as casks:
```
font-jetbrains-mono-nerd-font font-hack-nerd-font font-zed-mono-nerd-font font-meslo-lg-nerd-font font-adwaita-mono-nerd-font font-commit-mono-nerd-font font-fira-code-nerd-font
```
