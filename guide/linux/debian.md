# packages

## full upgrade
```bash
sudo nala upgrade -y && brew upgrade -y && flatpak update -y
```

## upgrade to a new Debian release

```bash
sudo apt update
sudo apt full-upgrade
```

Check the [release notes](https://www.debian.org/releases/stable/release-notes/) for the target release. Update the Debian repository entries in `/etc/apt/sources.list` and any files under `/etc/apt/sources.list.d/` to use the target release's codename. Review third-party repositories separately and disable those that do not support the target release. Then run:

```bash
sudo apt update
sudo apt upgrade --without-new-pkgs
sudo apt full-upgrade
sudo reboot
```

## cleanup system
```bash
sudo nala autoremove -y && sudo nala clean && brew autoremove && brew cleanup --prune=all && flatpak uninstall --unused -y
```

## WSL fast setup
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git -y
git clone https://github.com/tylerwhite-dev/Dotfiles
chmod +x ~/Dotfiles/dotfiles-deploy.sh
bash ~/Dotfiles/dotfiles-deploy.sh --wsl
```

### apt

basic
```
nala git git-lfs curl ssh zsh build-essential wl-clipboard wmctrl
``` 

common
```
flatpak firefox-esr alacritty timeshift gparted 
```

gnome
```
nautilus gnome-keyring gnome-console gnome-calculator gnome-calendar gnome-text-editor gnome-font-viewer baobab gcolor3 gnome-browser-connector gnome-tweaks gnome-control-center
```

dev
```
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
