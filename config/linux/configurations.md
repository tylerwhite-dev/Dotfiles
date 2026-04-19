# configurations

## zsh

make ZSH default shell
```
chsh -s $(which zsh) 
```

install plugins (pacman, homebrew, etc...)


add installation path to `~/.zshrc`
( some path contained in [`zshrc linux`](../crossplatform/zsh/zshrc%20linux) )

## starship 
( contained in [`zshrc linux`](../crossplatform/zsh/zshrc%20linux) )

go to: `~/.zshrc` file

```
eval "$(starship init zsh)"
```

## timeshift
if scheduled snapshots not working
```
sudo systemctl enable --now cronie.service
```

## nvm
```
nvm install --lts

nvm use node --lts

nvm --version
node -v
npm -v
```

## rustup
```
rustup default stable

rustc -V
cargo -V
rustup show
```

## docker
```
sudo usermod -aG docker $USER
sudo systemctl enable --now docker.service
```

reboot system
