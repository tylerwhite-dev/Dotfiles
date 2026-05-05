# packages

## full upgrade
```bash
sudo nala upgrade -y && brew upgrade && flatpak update -y
```

## cleanup system
```bash
sudo nala autoremove -y && sudo nala autoclean && brew cleanup && flatpak uninstall --unused -y
```

## apps (flatpak)

loupe - images;
decibels - music;
eartag - song tags;
vlc - video;
snapshot - camera.

### apt

```
nala sudo git git-lfs curl flatpak ssh zsh stow build-essential wl-clipboard wmctrl

nautilus gnome-keyring gnome-console gnome-calculator gnome-calendar gnome-text-editor gnome-font-viewer baobab gcolor3 gparted timeshift gnome-browser-connector gnome-tweaks gnome-control-center

qt6-base-dev qtcreator qt6-declarative-dev qml6-module-qtquick qml6-module-qtquick-controls
```

### brew

some could be installed as brew:
[installation and formulae](brew.md)

# configurations

most configurations contained in [`configurations file`](configurations.md)

## sudo

run as root:

```bash
sudo usermod -aG sudo USER_NAME
```

## ssh
```bash
systemctl enable --now ssh
```

## gui configurations
gnome settings contained in [`gnome.md`](gui/gnome.md)