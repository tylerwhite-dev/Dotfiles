#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT
export BREW_FIXTURE_OUTPUT="${fixture_dir}/output"
export BREW_FIXTURE_STATUS=0
export BREW_FIXTURE_ERROR=''
export BREW_FIXTURE_CALLS="${fixture_dir}/calls"

cat > "${fixture_dir}/brew" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" != --version ]]; then
  [[ "$HOMEBREW_NO_ANALYTICS" == 1 && "$HOMEBREW_NO_AUTO_UPDATE" == 1 ]]
fi
printf '%s\n' "$*" >> "$BREW_FIXTURE_CALLS"
case "$1" in
  list)
    [[ "$2" == --formula || "$2" == --cask ]]
    cat "$BREW_FIXTURE_OUTPUT"
    [[ -z "$BREW_FIXTURE_ERROR" ]] || printf '%s\n' "$BREW_FIXTURE_ERROR" >&2
    exit "$BREW_FIXTURE_STATUS"
    ;;
  --version) ;;
  install)
    [[ "${HOMEBREW_NO_INSTALL_UPGRADE:-0}" == "${BREW_FIXTURE_UPGRADE_POLICY:-1}" ]]
    ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "${fixture_dir}/brew"
executor_brew_bin() { printf '%s\n' "${fixture_dir}/brew"; }

# Real list execution returns only matching candidates, in candidate order.
printf '%s\n' fzf tmux unrelated tmux > "$BREW_FIXTURE_OUTPUT"
installed=(stale)
executor_brew_installed installed formula tmux zellij fzf
[[ "${installed[*]}" == 'tmux fzf' ]]
[[ "$(cat "$BREW_FIXTURE_CALLS")" == 'list --formula' ]]

printf '%s\n' firefox obsidian > "$BREW_FIXTURE_OUTPUT"
executor_brew_installed installed cask steam firefox
[[ "${installed[*]}" == firefox ]]
[[ "$(tail -n 1 "$BREW_FIXTURE_CALLS")" == 'list --cask' ]]

# Empty output and missing Homebrew are valid empty results.
: > "$BREW_FIXTURE_OUTPUT"
executor_brew_installed installed formula tmux
[[ "${#installed[@]}" == 0 ]]
(
  executor_brew_bin() { printf '%s\n' "${fixture_dir}/missing-brew"; }
  installed=(stale)
  executor_brew_installed installed formula tmux
  [[ "${#installed[@]}" == 0 ]]
)

# Failure must preserve stderr and discard even partial output.
BREW_FIXTURE_STATUS=7
BREW_FIXTURE_ERROR='fixture list failed'
for output in '' tmux; do
  printf '%s' "$output" > "$BREW_FIXTURE_OUTPUT"
  installed=(stale)
  actual=0
  executor_brew_installed installed formula tmux 2>"${fixture_dir}/error" || actual=$?
  [[ "$actual" == 7 && "${#installed[@]}" == 0 ]]
  grep -Fxq 'fixture list failed' "${fixture_dir}/error"
done

# The install policy reaches the executable through the real retry/env chain.
BREW_FIXTURE_STATUS=0
BREW_FIXTURE_ERROR=''
HOMEBREW_NO_INSTALL_UPGRADE=0
workflow_select_packages homebrew_extended tmux
action_install_homebrew_extended macos '' >/dev/null
workflow_select_packages homebrew_casks firefox
action_install_homebrew_casks macos '' >/dev/null
[[ "$HOMEBREW_NO_INSTALL_UPGRADE" == 0 ]]
[[ "$(tail -n 2 "$BREW_FIXTURE_CALLS")" == $'install tmux\ninstall --cask firefox' ]]

# Homebrew preparation never installs formulae; the core step owns the base set.
: > "$BREW_FIXTURE_CALLS"
action_install_homebrew macos '' >/dev/null
[[ "$(cat "$BREW_FIXTURE_CALLS")" == --version ]]
BREW_FIXTURE_UPGRADE_POLICY=0 action_install_core_cli_tools macos '' >/dev/null
[[ "$(tail -n 1 "$BREW_FIXTURE_CALLS")" == 'install starship zsh-autosuggestions zsh-syntax-highlighting pfetch-rs herdr superfile zip zoxide fzf eza stow' ]]

# Core tools require Homebrew, while other Brew procedures remain independent.
workflow_reset
workflow_select core_cli_tools yes
workflow_selected selected fedora
[[ "${#selected[@]}" == 0 ]]
workflow_select homebrew yes
workflow_selected selected fedora
[[ "${selected[*]}" == 'homebrew core_cli_tools' ]]
workflow_select core_cli_tools no
workflow_select homebrew_fonts yes
workflow_select homebrew_extended yes
workflow_selected selected fedora
[[ "${selected[*]}" == 'homebrew homebrew_fonts homebrew_extended' ]]

printf 'Homebrew probe and install policy validation passed.\n'
