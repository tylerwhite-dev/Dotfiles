# shell

## zsh

make ZSH default shell
```bash
chsh -s $(/bin/zsh)
```

# services and groups

## timeshift
if scheduled snapshots not working
```bash
sudo systemctl enable --now cronie.service
```

## docker
```bash
sudo usermod -aG docker $USER
sudo systemctl enable --now docker.service
```

## tio
```bash
sudo usermod -aG uucp $USER
```

## virtualbox
```bash
sudo usermod -aG vboxusers $USER
```

reboot system
