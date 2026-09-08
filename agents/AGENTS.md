# Dotfiles Repository Agent Instructions

## Setup Commands

- Full Linux setup: `bash script/dotfiles-deploy.sh`
- Dry run: `SETUP_DRY_RUN=1 bash script/dotfiles-deploy.sh`
- Apply configs only: `stow --no-folding .`
- Apply common Zsh config: `stow --no-folding zsh_common`
- Apply platform Zsh config: `stow --no-folding zsh_linux` or
  `stow --no-folding zsh_mac`

## Key Architecture Facts

- The setup implementation lives under `script/` and is organized into
  configuration, UI, business logic, actions, and execution adapters.
- Package and procedure declarations are separate from the code that applies
  them.
- GNU Stow creates symlinks for dotfiles and platform-specific Zsh settings.
- The setup script supports Arch, Debian/Ubuntu, and Fedora Linux.
- Homebrew provides most CLI tools and extensions on Linux.
- Detailed script interfaces and entities are documented in `script/AGENTS.MD`.

## Important Commands

- Check SSH key: `ssh -T git@github.com`
- Git LFS setup: `git lfs install && git lfs fetch && git lfs checkout`
- Submodule setup: `git submodule init && git submodule update`

## Repo Conventions

- Dotfiles organized by system type (Linux/macOS)
- Setup code and tests live in `script/`
- Configuration guides in `guide/` directory
- Platform-specific ZSH configs in `zsh_linux/` and `zsh_mac/`
