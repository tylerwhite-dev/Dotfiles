# gnome

## shell settings

enable experimental scaling features

``` bash
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'xwayland-native-scaling']"
```

center new windows on the screen

``` bash
gsettings set org.gnome.mutter center-new-windows true
```

smart focus behavior for new windows

``` bash
gsettings set org.gnome.desktop.wm.preferences focus-new-windows 'smart'
```

## theme for qt apps
TODO

## theme for legacy gtk apps

install:
```
adw-gtk-theme
```

light theme:
``` bash
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' && gsettings set org.gnome.desktop.interface color-scheme 'default'
```

dark theme:
``` bash
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' && gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

revert to default:
``` bash
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' && gsettings set org.gnome.desktop.interface color-scheme 'default'
```