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
brew install --cask firefox google-chrome librewolf zen ungoogled-chromium tor-browser telegram whatsapp discord slack zoom qbittorrent amneziavpn obsidian libreoffice bitwarden veracrypt iina vlc spotify figma inkscape drawio blender audacity obs zed visual-studio-code vscodium android-studio intellij-idea qt-creator iterm2 ghostty cmux warp wezterm docker-desktop hermes-desktop lm-studio wireshark-app raycast maccy rectangle alt-tab jordanbaird-ice betterdisplay mos linearmouse karabiner-elements hammerspoon stats coconutbattery appcleaner macfuse balenaetcher raspberry-pi-imager utm steam playcover-community
```

## shell

```bash
brew install starship zoxide fzf eza zsh-autosuggestions zsh-syntax-highlighting pfetch-rs fastfetch taproom herdr tmux zellij
```

## utilities

```bash
brew install lazygit lazyjournal lazydocker mailsy tio yazi superfile zip stow nvtop btop macmon typtea typioca
```

## developer

```bash
brew install fresh-editor neovim mise nvm rustup uv sdkman-cli go qt zig bun cmake ninja
```

The deploy script adds and trusts `sdkman/tap` when `sdkman-cli` is selected.
For manual installation, run `brew tap sdkman/tap` and
`brew trust --tap sdkman/tap` before installing it.

## media

```bash
brew install yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full
```

## CLI harness

```bash
brew install opencode hermes-agent codex claude-code antigravity-cli openclaw
```

## fonts

```bash
brew install --cask font-jetbrains-mono-nerd-font font-hack-nerd-font font-zed-mono-nerd-font font-meslo-lg-nerd-font font-adwaita-mono-nerd-font font-commit-mono-nerd-font font-fira-code-nerd-font
```

# configurations

## starship

( contained in [`zshrc macos`](../../zsh_mac/.zshrc) )

add to file ~/.zshrc (contained in `.zshrc macos`)

```bash
eval "$(starship init bash)"
```
