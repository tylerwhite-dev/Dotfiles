# Install Arch Linux with archinstall

Boot from the Arch Linux installation media and connect to the internet. Then
run the following commands in the live environment.

Install Git:

```bash
pacman -Sy git
```

Create a directory for the repository:

```bash
mkdir -p ~/repo
cd ~/repo
```

Clone the dotfiles repository:

```bash
git clone https://github.com/tylerwhite-dev/Dotfiles.git
```

Start archinstall with the configuration from the repository:

```bash
archinstall --config ./Dotfiles/script/archinstall/user_configuration.json
```

Review the settings in archinstall, configure the disk and user account, and
check the selected disk before starting the installation.
