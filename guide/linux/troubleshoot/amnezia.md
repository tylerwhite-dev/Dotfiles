# amnezia

[connection bug on Arch](https://github.com/amnezia-vpn/amnezia-client/issues/792#issuecomment-2508097498)

```bash
sudo systemctl enable systemd-resolved.service && sudo systemctl start systemd-resolved.service
```

```bash
sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

restart NetworkManager
```bash
sudo systemctl restart NetworkManager
```