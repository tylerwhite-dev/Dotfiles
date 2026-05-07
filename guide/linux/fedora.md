# packages

## full upgrade
```bash
sudo dnf upgrade -y && brew upgrade && flatpak update -y
```

## cleanup system
```bash
sudo dnf autoremove -y && brew cleanup && flatpak uninstall --unused -y 
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
