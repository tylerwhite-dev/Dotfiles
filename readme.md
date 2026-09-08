# Dotfiles

## Set up a Linux environment

The interactive setup script installs the selected native and Homebrew
packages, can set Zsh as the default shell, and applies the repository
configuration with GNU Stow. It supports Arch, Debian/Ubuntu, and Fedora.

### Full setup
```bash
bash script/dotfiles-deploy.sh
```

The questionnaire collects all choices before making changes. The final menu
opens on `Start execution` and also provides restart and exit options.

### Dry run
```bash
SETUP_DRY_RUN=1 bash script/dotfiles-deploy.sh
```

Dry-run mode shows the commands that would be executed without installing
packages or changing system files.

For the procedure list, package groups, architecture, and tests, see
[`script/README.md`](script/README.md) and [`script/AGENTS.MD`](script/AGENTS.MD).

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
