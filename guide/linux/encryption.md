# create encrypted drive using cryptsetup

1. find device name
```bash
lsblk -f
```

2. create luks container
```bash
sudo cryptsetup luksFormat /dev/sda1
```

3. open luks container
```bash
sudo cryptsetup open /dev/sda1 backup
```

4. format container
```bash
sudo mkfs.ext4 /dev/mapper/backup
```

5. create mountpoint
sudo mkdir -p /mnt/secure

6. mount container to mountpoint
```bash
sudo mount /dev/mapper/backup /mnt/secure
```

7. check created container
```bash
df -h /mnt/secure
lsblk -f
```

8. unmount drive
```bash
sudo umount /mnt/secure
sudo cryptsetup close backup
```

