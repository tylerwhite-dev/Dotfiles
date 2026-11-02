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
    if [[ "$SETUP_MODE" == mac ]]; then
      [[ "${#initial[@]}" == 0 ]]
    else
      for package in starship eza stow; do
        [[ " ${initial[*]} " == *" $package "* ]]
      done
    fi
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
      server) expected='native_packages zsh_default homebrew dotfiles'; count=1 ;;
      desktop) expected='native_packages zsh_default homebrew dotfiles'; count=3 ;;
      wsl) expected='native_packages zsh_default homebrew dotfiles'; count=1 ;;
      mac) expected='macos_command_line_tools macos_finder macos_spaces homebrew dotfiles'; count=3 ;;
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
[[ "${selected[*]}" == 'native_packages zsh_default homebrew homebrew_fonts homebrew_extended flatpak_apps dotfiles' ]]
for procedure in homebrew_fonts homebrew_extended flatpak_apps; do
  workflow_selected_packages packages "$procedure"
  [[ "${#packages[@]}" == 1 ]]
done

# Base defaults depend on zsh selection; missing/no answers keep installed presets only.
for zsh_answer in yes no unset; do
  workflow_reset
  if [[ "$zsh_answer" != unset ]]; then
    workflow_select zsh_default "$zsh_answer"
  fi
  workflow_installed_packages() { local -n result="$1"; result=(tmux starship); }
  ui_multiselect_grouped() {
    local -n result="$1" initial="$6"
    local -a defaults=()
    homebrew_extended_default_packages defaults
    if [[ "$zsh_answer" == yes ]]; then
      [[ "${#initial[@]}" == $((${#defaults[@]} + 1)) ]]
      for package in "${defaults[@]}"; do
        [[ " ${initial[*]} " == *" $package "* ]]
      done
    else
      [[ "${initial[*]}" == 'tmux starship' ]]
    fi
    # Users can change the list regardless of its defaults.
    result=(stow tmux)
  }
  _questionnaire_read_selectable_packages homebrew_extended fedora 1 1
  workflow_selected_packages packages homebrew_extended
  [[ "${packages[*]}" == 'stow tmux' ]]
done

# --add-optionals resets zsh selection and must not preselect the base set.
workflow_installed_packages() { local -n result="$1"; result=(); }
ui_multiselect_grouped() {
  local -n result="$1" initial="$6"
  [[ "${#initial[@]}" == 0 ]]
  result=()
}
workflow_select zsh_default yes
questionnaire_collect_optionals fedora Fedora
workflow_selected_packages packages homebrew_extended
[[ "${#packages[@]}" == 0 ]]
workflow_selection selection zsh_default
[[ "$selection" == no ]]
printf 'Scenario validation passed.\n'
