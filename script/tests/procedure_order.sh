#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"
error_output="$(mktemp)"
trap 'rm -f -- "$error_output"' EXIT

# Queue order controls discovery, YOLO selection and the actual runner.
procedure_order dotfiles native_packages
catalog_validate
workflow_available available fedora
[[ "${available[*]}" == 'dotfiles native_packages' ]]
_app_collect_yolo_selection fedora > /dev/null
workflow_selected selected fedora
[[ "${selected[*]}" == 'dotfiles native_packages' ]]
events=()
process_run() { events+=("$1"); }
runner_run fedora Fedora /fixture > /dev/null
[[ "${events[*]}" == 'action_apply_dotfiles action_install_native_packages' ]]

# Disabled procedures cannot return through stale manual selections or optionals.
workflow_select homebrew yes
workflow_select homebrew_extended yes
workflow_select flatpak_apps yes
workflow_select_packages flatpak_apps org.telegram.desktop
workflow_selected selected fedora
[[ "${selected[*]}" == 'dotfiles native_packages' ]]
workflow_available_optionals available fedora
[[ "${#available[@]}" == 0 ]]
workflow_reset
workflow_selection answer flatpak_apps
workflow_selected_packages packages flatpak_apps
[[ "$answer" == no && "${#packages[@]}" == 0 ]]

# Omitted prerequisites disable dependants in both standard and optional flows.
procedure_order homebrew_extended homebrew_casks flatpak_apps
catalog_validate
workflow_available available macos
[[ "${#available[@]}" == 0 ]]
workflow_available_optionals available fedora
[[ "${available[*]}" == flatpak_apps ]]
workflow_select homebrew yes
workflow_select homebrew_extended yes
workflow_selected selected fedora
[[ "${#selected[@]}" == 0 ]]

# An optional procedure still works when it alone is explicitly queued.
procedure_order flatpak_apps
ui_stage() { :; }
ui_multiselect_grouped() { local -n result="$1"; result=(org.telegram.desktop); }
questionnaire_collect_optionals fedora Fedora
workflow_selected_optionals selected fedora
[[ "${selected[*]}" == flatpak_apps ]]
events=()
runner_run_optionals fedora Fedora /fixture > /dev/null
[[ "${events[*]}" == action_prepare_flatpak ]]

# Missing requirements also disable a transitive chain.
queue_fixture_handler() { :; }
for id in queue_a queue_b queue_c; do
  procedure_define "$id"
  procedure_handler "$id" queue_fixture_handler
  procedure_platforms "$id" fedora
  message_define "procedure.${id}.question" "$id?"
  message_define "procedure.${id}.label" "$id"
  message_define "procedure.${id}.description" "$id"
done
procedure_requires queue_b queue_a
procedure_requires queue_c queue_b
procedure_order queue_b queue_c
catalog_validate
catalog_procedure_ids available
[[ "${#available[@]}" == 0 ]]

# An empty queue is valid and executes no procedure.
procedure_order
catalog_validate
_app_collect_yolo_selection fedora > /dev/null
workflow_selected selected fedora
[[ "${#selected[@]}" == 0 ]]
events=()
runner_run fedora Fedora /fixture > /dev/null
[[ "${#events[@]}" == 0 ]]
workflow_available_optionals available fedora
[[ "${#available[@]}" == 0 ]]

assert_invalid_order() {
  local expected="$1"
  shift
  procedure_order "$@"
  if catalog_validate 2> "$error_output"; then exit 1; fi
  grep -F -- "$expected" "$error_output" > /dev/null
}
assert_invalid_order 'unknown procedure: unknown' unknown
assert_invalid_order 'duplicate: dotfiles' dotfiles dotfiles
assert_invalid_order 'place homebrew before homebrew_extended' homebrew_extended homebrew
procedure_requires queue_a queue_a
assert_invalid_order 'place queue_a before queue_a' queue_a

# Optionals must not invoke an omitted CLT procedure during manager preparation.
(
  procedure_order homebrew homebrew_casks
  catalog_validate
  executor_brew_bin() { printf '/fixture/nonexistent-brew'; }
  questionnaire_collect_optionals() { workflow_reset; workflow_select homebrew_casks yes; }
  questionnaire_confirm() { printf -v "$1" start; }
  ui_select() { printf -v "$1" 0; }
  action_prepare_macos_command_line_tools() { exit 77; }
  action_install_macos_command_line_tools() { exit 77; }
  action_install_homebrew_binary() { events+=(brew); }
  runner_run_optionals() { events+=(run); }
  events=()
  _app_run_optionals macos macOS > /dev/null
  [[ "${events[*]}" == 'brew run' ]]
)

printf 'Procedure order validation passed.\n'
