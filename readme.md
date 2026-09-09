# Dotfiles

## Set up a Linux environment

The interactive setup script installs the selected native and Homebrew
packages, can set Zsh as the default shell, and applies the repository
configuration with GNU Stow. It supports Arch, Debian/Ubuntu, and Fedora.

### Setup
```bash
bash dotfiles-deploy.sh
```

There are also additional flags (e.g. `--yolo`, `--dry-run`, `--help`). See
[`script/README.md`](script/README.md).

## Apply configs only with Stow

Run these commands from the repository root.

### Common Zsh configuration

```bash
stow --no-folding zsh_common
```

### Platform-specific Zsh configuration

```bash
stow --no-folding zsh_linux  # Linux
stow --no-folding zsh_mac    # macOS
```

### Other configurations

```bash
stow --no-folding .
```
