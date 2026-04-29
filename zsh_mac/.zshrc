# alias
alias ll='eza -a --tree --level=1 --icons'
alias la='eza -la --header --icons --group-directories-first'
alias ld='eza --tree --level=2 --icons --git'

# enable history
setopt APPEND_HISTORY

# save history to
export HISTFILE=~/.zsh_history

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
eval "$(/opt/homebrew/bin/brew shellenv)"

# <-- starship --> 
eval "$(starship init zsh)"

# <-- zsh plugins -->
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# <-- nvm -->
# official way
# export NVM_DIR="$HOME/.nvm"
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# lazy nvm load on request
__nvmload() {
  unset -f nvm node npm npx __nvmload
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

# nvm placeholders
nvm() {
__nvmload()
  nvm "$@"
}
node() {
__nvmload()
  node "$@"
}
npm() {
__nvmload()
  npm "$@"
}
npx() {
__nvmload()
  npx "$@"
}

# <-- rustup -->
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# <-- sdkman -->
# source "$HOME/.sdkman/bin/sdkman-init.sh"

pfetch