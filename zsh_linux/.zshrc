# <-- homebrew -->
__HOMEBREW=/home/linuxbrew/.linuxbrew

# <-- nix -->
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi

# <-- common part -->
source $HOME/.common.zshrc
