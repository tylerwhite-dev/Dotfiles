# I use arch btw

# packages

## full no confirm update
```
sudo pacman -Syu --noconfirm && yay -Syu --noconfirm && flatpak update -y && brew upgrade
```

## apps

loupe (flatpak) - images;
decibels - music;
eartag (flatpak) - song tags;
vlc (flatpak) - video;
snapshot - camera.

### pacman

``` 
flatpak openssh cronie wl-clipboard fwupd wmctrl

gnome-shell gdm gnome-console gnome-keyring nautilus sushi gnome-browser-connector gnome-tweaks gnome-control-center gnome-calculator gnome-clocks gnome-calendar decibels gnome-text-editor gnome-font-viewer baobab snapshot gcolor3

firefox alacritty gparted veracrypt virtualbox virtualbox-host-dkms timeshift

qtcreator qt6-base docker
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
```
sudo systemctl enable --now sshd.service
```

## fwupd
```
sudo systemctl status fwupd.service
```

## amnezia
install via AUR or get [from github](https://github.com/amnezia-vpn/amnezia-client/releases) (recommended)

amnezia has connection bug on Arch, checkout [troubleshoot](troubleshoot/amnezia.md)

## printers

``` bash
sudo pacman -S cups cups-pdf
```

``` bash
sudo systemctl enable --now cups.service
```

``` bash
sudo gpasswd -a $USER lp
```

## gui configurations
gnome settings contained in [`gnome.md`](gui/gnome.md)