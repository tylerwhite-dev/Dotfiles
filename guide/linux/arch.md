# I use arch btw

# packages

## full upgrade
```bash
yay -Syyu && brew upgrade && flatpak update -y
```

## cleanup system
```bash
sudo pacman -Sc && sudo pacman -Qdtq | sudo pacman -Rns - ; yay -Yc && brew cleanup && flatpak uninstall --unused -y
```

## apps
`
loupe - images;
decibels - music;
eartag - song tags;
vlc - video;
snapshot - camera.
`

### pacman

basic
```
openssh cronie wl-clipboard fwupd wmctrl
```

common
```
flatpak firefox alacritty ghostty gparted veracrypt virtualbox virtualbox-host-dkms timeshift zed
```

gnome
```
gnome-shell gdm gnome-console gnome-keyring nautilus sushi gnome-browser-connector gnome-tweaks gnome-control-center gnome-calculator gnome-clocks gnome-calendar gnome-text-editor gnome-font-viewer baobab gcolor3
```

dev
```
qtcreator qt6-base docker
```

system
```
dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g 
```

dependencies
```
xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor
```

### yay

```
google-chrome lmstudio balena-etcher vscodium-bin
```

### brew

some could be installed as brew:
[installation and formulae](brew.md)

# configurations

most configurations contained in [`configurations file`](configurations.md)

## ssh
```bash
sudo systemctl enable --now sshd.service
```

## fwupd
```bash
sudo systemctl status fwupd.service
```

## amnezia
install via AUR or get [from github](https://github.com/amnezia-vpn/amnezia-client/releases) (recommended)

amnezia has connection bug on Arch, checkout [troubleshoot](troubleshoot/amnezia.md)

## printers

```bash
sudo pacman -S cups cups-pdf
```

```bash
sudo systemctl enable --now cups.service
```

```bash
sudo gpasswd -a $USER lp
```

## gui configurations
gnome settings contained in [`gnome.md`](gui/gnome.md)