# Dotfiles

## Apply dotfiles and packages via Ansible

Ansible playbook provides basic package installations via apt/pacman/dnf, many tools via brew, set ZSH as default shell, apply dotfiles

### Basic installation
```bash
bash ansible/bootstrap.sh
```

### Extended brew installation
```bash
bash ansible/bootstrap.sh -e "extended=true"
```

The bootstrap script installs the pinned Ansible collection dependencies before
running the playbook. The repository can be cloned into any directory; the
playbook derives the Stow source path from its own location.

### Run tasks with specific tag
```bash
bash ansible/bootstrap.sh --tags apps
```

## Apply configs only via stow

### ZSH

common part
```
stow zsh_common
```

mac or linux part
```
stow zsh_mac
```
```
stow zsh_linux
```

### The rest of configurations
```
stow --no-folding .
```
