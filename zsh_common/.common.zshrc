# <-- homebrew -->
eval "$($__HOMEBREW/bin/brew shellenv)"

HOMEBREW_NO_ENV_HINTS=1

# <-- herdr on startup -->
if [[ "$TERM_PROGRAM" == "ghostty" && "$SHLVL" -eq 1 ]]; then
  if command -v herdr &> /dev/null && [ -z "$HERDR_CLIENT" ]; then
    herdr
  fi
fi

# <-- alias -->
# directory view
alias ll=' eza -xA --icons --group-directories-first'
# details view
alias la='eza -la --header --icons --group-directories-first'
# tree view
alias ld='eza --tree --level=2 --icons --git'

#  <-- settings -->
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

# <-- starship -->
eval "$(starship init zsh)"

# <-- zsh plugins -->
source $__HOMEBREW/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $__HOMEBREW/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# <-- zoxide -->
eval "$(zoxide init zsh)"

# <-- nvm -->
# lazy nvm load on request installed by brew
__nvmload() {
  unset -f nvm node npm npx __nvmload 2>/dev/null
  export NVM_DIR="$HOME/.nvm"
  source $__HOMEBREW/opt/nvm/nvm.sh 2>/dev/null || echo "Warning: nvm.sh not found"
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
export PATH="$__HOMEBREW/opt/rustup/bin:$PATH"

# <-- sdkman -->
if [ -e $__HOMEBREW/opt/sdkman-cli/libexec/bin/sdkman-init.sh ]; then
  export SDKMAN_DIR="$__HOMEBREW/opt/sdkman-cli/libexec"
  source "${SDKMAN_DIR}/bin/sdkman-init.sh"
fi

pfetch
