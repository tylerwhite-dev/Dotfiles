install and enable zram-generator

fedora

```bash
sudo dnf install zram-generator-defaults
```

open config

```bash
sudo nano /etc/systemd/zram-generator.conf
```

add properties

```
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
```

restart and enable

```bash
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
```

check

```bash
zramctl
swapon --show
```
