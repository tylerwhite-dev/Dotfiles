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

for mac or linux
```
stow zsh-mac
```
```
stow zsh-linux
```

### The rest of configurations
```
stow .
```