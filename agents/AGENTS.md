# Dotfiles Repository Agent Instructions

## Setup Commands

- Full setup: `ansible-playbook ansible/desktop.yml --ask-become-pass`
- Apply configs only: `stow .`
- Apply ZSH configs: `stow zsh-linux` (Linux) or `stow zsh-mac` (macOS)

## Key Architecture Facts

- Uses Ansible for package management and dotfiles deployment
- Uses GNU Stow for dotfiles symlinking
- Supports both Linux (apt) and macOS (brew) systems
- ZSH configuration files are platform-specific (zsh_linux/ zsh_mac/)
- Homebrew used for most CLI tools and extensions on Linux

## Important Commands

- Check SSH key: `ssh -T git@github.com`
- Git LFS setup: `git lfs install && git lfs fetch && git lfs checkout`
- Submodule setup: `git submodule init && git submodule update`

## Repo Conventions

- Dotfiles organized by system type (Linux/macOS)
- Ansible playbooks in `ansible/` directory
- Configuration guides in `guide/` directory
- Platform-specific ZSH configs in `zsh_linux/` and `zsh_mac/`