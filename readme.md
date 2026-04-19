# Dotfiles

## Apply dotfiles and packages via Ansible

Ansible playbook provides basic package installations via apt/pacman, many tools via brew, set ZSH as default shell, apply dotfiles

```bash
ansible-playbook ansible/desktop.yml --ask-become-pass
```

## Only configs via stow

### ZSH

for mac or linux
```
stow zsh-mac
```
```
stow zsh-linux
```

## The rest of configurations
```
stow .
```