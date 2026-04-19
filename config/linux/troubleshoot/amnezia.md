# amnezia

[connection bug on Arch](https://github.com/amnezia-vpn/amnezia-client/issues/792#issuecomment-2508097498)

```
sudo systemctl enable systemd-resolved.service && sudo systemctl start systemd-resolved.service
```

```
sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

restart NetworkManager
```
sudo systemctl restart NetworkManager
```