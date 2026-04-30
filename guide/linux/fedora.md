# packages

## full upgrade
```bash
sudo nala upgrade -y && flatpak update -y && brew upgrade
```

## cleanup system
```bash
sudo nala autoremove -y && sudo nala autoclean && flatpak uninstall --unused -y && brew cleanup
```

## apps

loupe (flatpak) - images;
decibels - music;
eartag (flatpak) - song tags;
vlc (flatpak) - video;
snapshot - camera.

### apt

```
git git-lfs curl flatpak ssh zsh stow wl-clipboard wmctrl

nautilus gnome-keyring gnome-console gnome-calculator gnome-calendar gnome-text-editor gnome-font-viewer baobab gcolor3 gparted timeshift gnome-browser-connector gnome-tweaks gnome-control-center
```