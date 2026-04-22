# shell

## zsh

make ZSH default shell
```bash
chsh -s $(/bin/zsh)
```

# services

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

reboot system


# toolchains

## nvm
```bash
nvm install --lts
nvm use node --lts

nvm --version
node -v
npm -v
```

## rustup
```bash
rustup default stable

rustc -V
cargo -V
rustup show
```