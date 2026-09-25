# I use arch btw

# packages

## full upgrade
```bash
yay -Syyu && brew upgrade -y && flatpak update -y
```

## cleanup system
```bash
yay -Scc && brew cleanup && flatpak uninstall --unused -y
```

## WSL fast setup

Install the official Arch Linux WSL image from PowerShell:

```powershell
wsl --install archlinux
```

On the first launch, Arch opens as `root`. Run these commands in Arch WSL:

```bash
pacman -Syu --noconfirm && pacman -S --needed git sudo --noconfirm
ARCH_USER=tyler
useradd -m -G wheel -s /bin/bash "$ARCH_USER"
passwd "$ARCH_USER"
printf '%s\n' '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -cf /etc/sudoers
```

Set that user as the WSL default from PowerShell, then reopen Arch:

```powershell
wsl --manage archlinux --set-default-user tyler
```

Run the deployment as the new user:

```bash
git clone https://github.com/tylerwhite-dev/Dotfiles
chmod +x ~/Dotfiles/dotfiles-deploy.sh
bash ~/Dotfiles/dotfiles-deploy.sh
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
flatpak firefox alacritty ghostty gparted veracrypt virtualbox virtualbox-host-dkms linux-headers timeshift zed
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
