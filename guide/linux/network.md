# manual IP

## check NetworkManager status

```bash
systemctl is-active NetworkManager
```

## configure connection

### show current connections

```bash
nmcli connection show
```

### setup connection

```bash
sudo nmcli connection modify "NAME" \
  ipv4.method manual \
  ipv4.addresses "192.168.88.224/24" \
  ipv4.gateway "192.168.1.1" \
  ipv4.dns "8.8.8.8 1.1.1.1"
```

### apply configuration

```bash
sudo nmcli con reload && sudo nmcli device reapply "DEVICE"
```

> may drop SSH connection when changing IP/gateway

### verify

```bash
nmcli connection show "NAME" | grep ipv4
```

### rollback to DHCP

```bash
sudo nmcli connection modify "NAME" \
  ipv4.method auto \
  ipv4.addresses "" \
  ipv4.gateway "" \
  ipv4.dns "" && sudo nmcli con up "NAME"
```
