#!/usr/bin/env bash
set -Eeuo pipefail
script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

# Exercise the real collector with only terminal rendering and input replaced.
ui_stage() { :; }
ui_multiselect_grouped() {
  local -n result="$1" rows_ref="$4" kinds_ref="$5"
  local index
  result=()
  for ((index=0; index<${#rows_ref[@]}; index++)); do
    if [[ "${kinds_ref[index]}" == i ]]; then result+=("${rows_ref[index]}"); break; fi
  done
}
for platform in arch debian fedora macos; do
  questionnaire_collect_optionals "$platform" "$platform"
  workflow_selected_optionals selected "$platform"
  if [[ "$platform" == macos ]]; then
    [[ "${selected[*]}" == 'homebrew_extended homebrew_casks' ]]
  else
    [[ "${selected[*]}" == 'homebrew_extended flatpak_apps' ]]
  fi
  # Ordinary prerequisites remain unchanged in the standard scenario.
  workflow_selected standard "$platform"
  if [[ "$platform" == macos ]]; then [[ "${#standard[@]}" == 0 ]];
  else [[ "${standard[*]}" == flatpak_apps ]]; fi
done

# The optional review displays only selectable lists, not unrelated settings.
summary_labels=()
ui_summary_item_packages() { summary_labels+=("$1"); }
ui_summary_item() { exit 1; }
_questionnaire_show_summary macos macOS optionals
[[ "${#summary_labels[@]}" == 2 ]]

# Both runners use the same process seam, including direct-input finish handlers.
events=()
ui_notice() { :; }
ui_success() { :; }
process_run() { events+=("$1:$8"); }
runner_run_optionals macos macOS ''
[[ "${events[*]}" == 'action_install_homebrew_extended: action_prepare_homebrew_casks:action_install_homebrew_casks' ]]
questionnaire_collect_optionals fedora Fedora
events=()
runner_run_optionals fedora Fedora ''
[[ "${events[*]}" == 'action_install_homebrew_extended: action_prepare_flatpak:action_install_flatpak_apps' ]]
process_run() { events+=("$1"); return 8; }
events=() actual=0
runner_run_optionals fedora Fedora '' || actual=$?
[[ "$actual" == 8 && "${events[*]}" == action_install_homebrew_extended ]]

printf 'Optional procedure validation passed.\n'
