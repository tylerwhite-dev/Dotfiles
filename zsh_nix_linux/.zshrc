# alias
alias ll='eza -a --icons --grid --group-directories-first'
alias la='eza -la --icons --group-directories-first'

# enable history
setopt APPEND_HISTORY

# save history to
HISTFILE=~/.zsh_history

# history file size
export HISTSIZE=500
export SAVEHIST=$HISTSIZE

# do not save trash commands
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# autosuggest using tab key
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select

# by-word autosuggest accept using ctrl + arrow right
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(forward-word)
bindkey '^[[1;5C' forward-word

# <-- nix -->
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi

# <-- starship -->
eval "$(starship init zsh)"

# <-- zsh plugins -->
source ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

pfetch

echo "on NIX btw"