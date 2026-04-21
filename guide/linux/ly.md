
1. Install zig and libs

```
build-essential libpam0g-dev libxcb-xkb-dev xauth xserver-xorg brightnessctl
```

2. Compile as systemd module
```
zig build installexe -Dinit_system=systemd
```

3. Disable tty2, enable ly
```
sudo systemctl daemon-reload

sudo systemctl disable --now gdm3  # disable current DM
sudo systemctl disable getty@tty2.service

sudo systemctl enable --now ly@tty2.service
```