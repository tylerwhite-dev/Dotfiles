#!/usr/bin/env bash
set -Eeuo pipefail
script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

[[ "$(WSL_DISTRO_NAME=Debian environment_is_wsl; printf '%s' "$?")" == 0 ]]
environment_is_wsl() { [[ "$test_wsl" == 1 ]]; }
for platform in arch debian fedora macos; do
  for test_wsl in 0 1; do
    for mode in server desktop wsl mac; do
      expected=1
      case "$mode:$platform:$test_wsl" in
        mac:macos:*) expected=0 ;;
        wsl:arch:1|wsl:debian:1|wsl:fedora:1) expected=0 ;;
        server:arch:0|server:debian:0|server:fedora:0|desktop:arch:0|desktop:debian:0|desktop:fedora:0) expected=0 ;;
      esac
      actual=0
      environment_scenario_matches "$mode" "$platform" || actual=$?
      [[ "$actual" == "$expected" ]]
    done
  done
done

# Collection performs no installations or yes/no prompts for mandatory steps.
ui_stage() { :; }
ui_select() { printf 'Unexpected yes/no prompt\n' >&2; return 1; }
workflow_installed_packages() { local -n result="$1"; result=(); }
ui_multiselect_grouped() {
  local -n result="$1" initial="$6"
  asked+=("$2")
  if [[ "$2" == *extended* ]]; then
    for package in starship zoxide fzf eza stow; do
      [[ " ${initial[*]} " == *" $package "* ]]
    done
  fi
  result=()
}
for SETUP_MODE in server desktop wsl mac; do
  for platform in arch debian fedora macos; do
    [[ "$SETUP_MODE" != mac || "$platform" == macos ]] || continue
    [[ "$SETUP_MODE" == mac || "$platform" != macos ]] || continue
    asked=()
    questionnaire_collect "$platform" "$platform"
    workflow_selected selected "$platform"
    case "$SETUP_MODE" in
      server) expected='native_packages zsh_default homebrew core_cli_tools dotfiles'; count=1 ;;
      desktop) expected='native_packages zsh_default homebrew core_cli_tools dotfiles'; count=3 ;;
      wsl) expected='native_packages zsh_default homebrew core_cli_tools dotfiles'; count=1 ;;
      mac) expected='macos_command_line_tools macos_finder macos_spaces homebrew core_cli_tools dotfiles'; count=3 ;;
    esac
    if [[ "$platform" == arch && "$SETUP_MODE" != server ]]; then
      expected="${expected/native_packages /native_packages yay }"
    fi
    [[ "${selected[*]}" == "$expected" ]]
    [[ "${#asked[@]}" == "$count" ]]
    # Restart must restore every mandatory selection and clear old choices.
    workflow_select native_packages no
    workflow_select_packages homebrew_extended tmux
    questionnaire_collect "$platform" "$platform"
    workflow_selected selected "$platform"
    [[ "${selected[*]}" == "$expected" ]]
    workflow_selected_packages packages homebrew_extended
    [[ "${#packages[@]}" == 0 ]]
  done
done

# Optional choices survive collection and reach the runner's selection.
SETUP_MODE=desktop
ui_multiselect_grouped() {
  local -n result="$1" rows_ref="$4" kinds_ref="$5"
  local index
  result=()
  for index in "${!rows_ref[@]}"; do
    if [[ "${kinds_ref[$index]}" == i ]]; then
      result=("${rows_ref[$index]}")
      break
    fi
  done
}
questionnaire_collect fedora Fedora
workflow_selected selected fedora
[[ "${selected[*]}" == 'native_packages zsh_default homebrew core_cli_tools homebrew_fonts homebrew_extended flatpak_apps dotfiles' ]]
for procedure in homebrew_fonts homebrew_extended flatpak_apps; do
  workflow_selected_packages packages "$procedure"
  [[ "${#packages[@]}" == 1 ]]
done

# Core formula presets also apply to the ordinary questionnaire.
SETUP_MODE=standard
workflow_reset
workflow_select core_cli_tools yes
asked=()
ui_multiselect_grouped() {
  local -n result="$1" initial="$6"
  for package in starship zoxide fzf eza stow; do
    [[ " ${initial[*]} " == *" $package "* ]]
  done
  result=()
}
_questionnaire_read_selectable_packages homebrew_extended fedora 1 1

# Clearing a checkbox cannot cancel the core installation. Installed presets
# remain checked even when core tools are not selected.
workflow_reset
workflow_installed_packages() { local -n result="$1"; result=(tmux); }
ui_multiselect_grouped() {
  local -n result="$1" initial="$6"
  [[ "${initial[*]}" == tmux ]]
  result=()
}
_questionnaire_read_selectable_packages homebrew_extended fedora 1 1
printf 'Scenario validation passed.\n'
