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

setopt CORRECT

# autosuggest using tab key
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select

# by-word autosuggest accept using ctrl + arrow right
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(forward-word)
bindkey '^[[1;5C' forward-word

# <-- homebrew -->
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# <-- starship -->
eval "$(starship init zsh)"

# <-- zsh plugins -->
# installed via brew
source /home/linuxbrew/.linuxbrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /home/linuxbrew/.linuxbrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# installed via pacman
# source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# installed via apt
# source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# <-- nvm -->
# official way to load
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# lazy nvm load on request installed recommended by script
# lazynvm() {
#   unset -f nvm node npm npx
#   export NVM_DIR="$HOME/.nvm"
#   [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
# }

# lazy nvm load on request installed by brew
__nvmload() {
  unset -f nvm node npm npx __nvmload 2>/dev/null
  export NVM_DIR="$HOME/.nvm"
  source /home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh 2>/dev/null || \
    echo "Warning: nvm.sh not found"
}

# nvm placeholders
nvm() {
  __nvmload
  nvm "$@"
}
node() {
  __nvmload
  node "$@"
}
npm() {
  __nvmload
  npm "$@"
}
npx() {
  __nvmload
  npx "$@"
}

# <-- rustup -->
export PATH="/home/linuxbrew/.linuxbrew/opt/rustup/bin:$PATH"

# <-- sdkman -->
# source "$HOME/.sdkman/bin/sdkman-init.sh"

pfetch