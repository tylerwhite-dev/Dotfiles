# Dotfiles

## Set up a Linux or macOS environment

The setup script installs native and Homebrew packages, configures Zsh, and
applies the repository configuration with GNU Stow. It supports Arch,
Debian/Ubuntu, Fedora, macOS, and supported Linux distributions running in WSL.

### Setup

After cloning the repository, install Git LFS and retrieve the files it tracks (mostly wallpapers)
from the repository root:

```bash
git lfs install
git lfs fetch
git lfs checkout
```

Run from the repository root. Without flags, the script asks which procedures
and packages to install:

```bash
bash dotfiles-deploy.sh
```

Choose a preset to accept its mandatory procedures automatically and select
only the optional packages:

```bash
bash dotfiles-deploy.sh --server
bash dotfiles-deploy.sh --desktop
bash dotfiles-deploy.sh --wsl
```

On macOS the script requires Bash 5 or newer. With Homebrew already installed,
install Bash and run the macOS preset:

```bash
brew install bash
"$(brew --prefix)/bin/bash" dotfiles-deploy.sh --mac
```

A clean Mac needs Command Line Tools and Homebrew prepared before installing
Bash. The setup script cannot bootstrap itself using the system Bash 3.2.

### Presets

| Flag | Mandatory procedures | Optional package lists |
| --- | --- | --- |
| `--server` | Native packages, Zsh as default shell, Homebrew, core CLI tools, dotfiles | Extended Homebrew |
| `--desktop` | Native packages, yay on Arch, Zsh as default shell, Homebrew, core CLI tools, dotfiles | Nerd Fonts, extended Homebrew, Flatpak apps |
| `--wsl` | Native packages, yay on Arch, Zsh as default shell, Homebrew, core CLI tools, dotfiles | Extended Homebrew |
| `--mac` | Apple Command Line Tools, Finder preferences, Spaces order, Homebrew, core CLI tools, dotfiles | Nerd Fonts, extended Homebrew, Homebrew casks |

`--server` and `--desktop` require Linux outside WSL, `--wsl` requires WSL,
and `--mac` requires macOS. A mismatched preset exits with an error. Distribution
checks remain in effect; yay is installed only on Arch.

Mandatory procedures cannot be disabled individually. Before execution, the
review screen offers Start, Restart, or Exit. Password prompts and system
installation dialogs may still require interaction. All presets apply the
complete dotfiles set; Linux presets use the same base package set.

Installed packages start checked in the optional lists. Extended Homebrew also
checks packages already scheduled through core CLI tools. Clearing a checkbox
does not uninstall a package or cancel its installation through a mandatory step.

### Other flags

- `-a`, `--add-optionals` selects optional packages without installing core CLI
  tools. If selected packages need missing Homebrew, the script asks to install
  it after the final review.
- `-h`, `--help` prints usage.

Pass at most one flag per run. The former `-y` / `--yolo` flag is no longer
supported. See [`deploy/README.md`](deploy/README.md) for execution details and
[`deploy/config/scenarios.sh`](deploy/config/scenarios.sh) for preset membership.

## Apply configs only with Stow

Run these commands from the repository root.

### Common Zsh configuration

```bash
stow --no-folding --override='.*' --target="$HOME" zsh_common
```

### Platform-specific Zsh configuration

```bash
stow --no-folding --override='.*' --target="$HOME" zsh_linux  # Linux
stow --no-folding --override='.*' --target="$HOME" zsh_mac    # macOS
```

### Other configurations

```bash
stow --no-folding --override='.*' --dir="$(dirname "$PWD")" --target="$HOME" "$(basename "$PWD")"
```

`--override` replaces links managed by another Stow package. Existing regular
files still cause a conflict and must be resolved separately.
