# I use arch btw

# packages

## full no confirm update
```
sudo pacman -Syu --noconfirm && yay -Syu --noconfirm && flatpak update -y && brew upgrade
```

## apps

### pacman

some could be installed as [brew](brew.md)
```
flatpak openssh cronie wl-clipboard fwupd wmctrl

firefox alacritty gparted veracrypt vlc vlc-plugins-all inkscape foliate eartag virtualbox virtualbox-host-dkms timeshift

qtcreator qt6-base docker
```

### yay
```
google-chrome lmstudio balena-etcher vscodium-bin
```

### brew
[installation and formulae](brew.md)


# configurations

some configurations contained in [`configurations file`](configurations.md)

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


# gui

## gnome

### base
```
gnome-shell gdm gnome-console gnome-keyring
```

### enable gdm
```
sudo systemctl enable gdm.service
```  

### apps

``` bash
sudo pacman -S nautilus sushi gnome-browser-connector gnome-tweaks gnome-control-center gnome-calculator gnome-clocks gnome-calendar loupe decibels gnome-text-editor gnome-font-viewer baobab snapshot gcolor3
```

loupe - images;
decibels - music;
eartag - song tags;
vlc - video;
snapshot - camera.

### extensions
``` bash
yay -S gnome-shell-extension-dash-to-panel gnome-shell-extension-rounded-window-corners-reborn
```

### configurations
gnome settings contained in [`gnome.md`](gui/gnome.md)