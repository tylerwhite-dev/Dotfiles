#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

# The group heading selects all fonts and is not itself a package.
catalog_package_rows font_rows font_kinds homebrew_fonts fedora brew_cask
catalog_packages font_packages homebrew_fonts fedora brew_cask
[[ "${font_rows[0]}" == All && "${font_kinds[0]}" == g ]]
[[ "${font_rows[*]:1}" == "${font_packages[*]}" ]]
declare -A font_texts=()
questionnaire_multiselect_texts font_texts
font_presets=(font-hack-nerd-font)
font_labels=("${font_rows[@]}")
ui_multiselect_grouped font_selection Prompt font_texts font_rows font_kinds font_presets font_labels \
  <<< $' \n' >/dev/null
[[ "${font_selection[*]}" == "${font_packages[*]}" ]]
font_presets=("${font_packages[@]}")
ui_multiselect_grouped font_selection Prompt font_texts font_rows font_kinds font_presets font_labels \
  <<< $' \n' >/dev/null
[[ "${#font_selection[@]}" == 0 ]]

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
executor_brew_installed installed all firefox missing
[[ "${installed[*]}" == firefox ]]
[[ "$(tail -n 2 "$BREW_FIXTURE_CALLS")" == $'list --formula\nlist --cask' ]]

# Extended CLI packages may be installed as casks on Linux or macOS.
# Keep candidate order, deduplicate matches, and discard partial probe results.
(
  _executor_brew_list() {
    case "$1" in
      formula) printf '%s\n' tmux opencode codex ;;
      cask) printf '%s\n' antigravity-cli claude-code codex openclaw ;;
      *) return 2 ;;
    esac
  }
  workflow_installed_packages installed homebrew_extended \
    opencode codex claude-code antigravity-cli openclaw missing tmux
  [[ "${installed[*]}" == 'opencode codex claude-code antigravity-cli openclaw tmux' ]]

  _executor_brew_list() {
    if [[ "$1" == formula ]]; then printf '%s\n' tmux; else return 7; fi
  }
  installed=(stale)
  actual=0
  workflow_installed_packages installed homebrew_extended tmux codex || actual=$?
  [[ "$actual" == 7 && "${#installed[@]}" == 0 ]]
)

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
workflow_select_packages homebrew_fonts font-hack-nerd-font
action_install_homebrew_fonts macos '' >/dev/null
[[ "$HOMEBREW_NO_INSTALL_UPGRADE" == 0 ]]
[[ "$(tail -n 3 "$BREW_FIXTURE_CALLS")" == $'install tmux\ninstall --cask firefox\ninstall --cask font-hack-nerd-font' ]]
workflow_select_packages homebrew_fonts
action_install_homebrew_fonts macos '' >/dev/null
[[ "$(tail -n 1 "$BREW_FIXTURE_CALLS")" == 'install --cask font-hack-nerd-font' ]]

# Homebrew preparation never installs formulae; the menu owns all formula choices.
: > "$BREW_FIXTURE_CALLS"
action_install_homebrew macos '' >/dev/null
[[ "$(cat "$BREW_FIXTURE_CALLS")" == --version ]]

# Clearing all formula choices never invokes brew install.
workflow_select_packages homebrew_extended
action_install_homebrew_extended macos '' >/dev/null
[[ "$(cat "$BREW_FIXTURE_CALLS")" == --version ]]

# Other Brew procedures require Homebrew independently.
workflow_reset
workflow_select homebrew_extended yes
workflow_selected selected fedora
[[ "${#selected[@]}" == 0 ]]
workflow_select homebrew yes
workflow_select homebrew_fonts yes
workflow_selected selected fedora
[[ "${selected[*]}" == 'homebrew homebrew_fonts homebrew_extended' ]]

printf 'Homebrew probe and install policy validation passed.\n'
