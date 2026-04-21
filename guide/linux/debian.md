# packages

## apt

update:
```
sudo nala upgrade -y && brew upgrade
```

some could be installed as [brew](brew.md)
```
nala sudo git git-lfs curl flatpak ssh zsh stow build-essential wl-clipboard wmctrl

nautilus gnome-keyring gnome-console gnome-calculator gnome-calendar loupe gnome-text-editor gnome-font-viewer baobab snapshot gcolor3 gparted vlc inkscape timeshift foliate eartag gnome-browser-connector gnome-tweaks gnome-control-center 

qt6-base-dev qtcreator qt6-declarative-dev qml6-module-qtquick qml6-module-qtquick-controls
```

## brew
[installation and formulae](brew.md)

## configurations

some configurations contained in [`configurations file`](configurations.md)

### sudo

run as root:

```
sudo usermod -aG sudo USER_NAME
```

### ssh
```
systemctl enable --now ssh
```
