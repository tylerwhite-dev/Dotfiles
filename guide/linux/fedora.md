# packages

## full upgrade
```bash
sudo dnf upgrade -y && brew upgrade && flatpak update -y
```

## cleanup system
```bash
sudo dnf autoremove -y && brew cleanup && flatpak uninstall --unused -y 
```

## disable repo

show all repos:
```bash
sudo dnf repolist
```

disable repo with ID (fedora-cisco-openh264 for example)
```bash
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=0
```

## apps
`
loupe - images;
decibels - music;
eartag - song tags;
vlc - video;
snapshot - camera.
`

### dnf

basic
```
git git-lfs curl flatpak ssh zsh stow wl-clipboard wmctrl
```

common
```
flatpak gparted timeshift 
```

gnome
```
nautilus gnome-keyring gnome-console gnome-calculator gnome-calendar gnome-text-editor gnome-font-viewer baobab gcolor3 gnome-browser-connector gnome-tweaks gnome-control-center
```
