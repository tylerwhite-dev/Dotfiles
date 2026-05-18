# Dotfiles

## Apply dotfiles and packages via Ansible

Ansible playbook provides basic package installations via apt/pacman/dnf, many tools via brew, set ZSH as default shell, apply dotfiles

### Basic installation
```bash
ansible-playbook ansible/desktop.yml -i ansible/inventory.yml -K
```

### Extended brew installation
```bash
ansible-playbook ansible/desktop.yml -i ansible/inventory.yml -K -e "extended_brew=true"
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
stow .
```