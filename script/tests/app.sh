#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

# All system-changing and environment operations below are test doubles.
ui_is_interactive() { return "${interactive_status:-0}"; }
catalog_validate() { return "${validation_status:-0}"; }
environment_detect() {
  printf -v "$1" '%s' fedora
  printf -v "$2" '%s' Fedora
  return "${environment_status:-0}"
}
message_format() { printf -v "$1" '%s' "$2"; }
ui_success() { events+=("$1"); }
ui_notice() { events+=("$1"); }
ui_ansi_palette() { :; }
error_report() { events+=("$1"); }
status_report() { events+=("$1"); }
runner_run() { events+=(run); return "${runner_status:-0}"; }
_app_print_elapsed_time() { events+=(elapsed); }
questionnaire_collect() { events+=(collect); return "${collect_status:-0}"; }
questionnaire_confirm() {
  printf -v "$1" '%s' "${answers[answer_index]}"
  ((answer_index+=1))
  return "${confirm_status:-0}"
}
executor_brew_bin() { printf '%s\n' "${brew_path:-/bin/bash}"; }
ui_select() { printf -v "$1" '%s' "${brew_choice:-0}"; return "${input_status:-0}"; }
action_install_homebrew_binary() { events+=(brew-install); return "${brew_status:-0}"; }
questionnaire_collect_optionals() { events+=(optional-collect); return "${optional_status:-0}"; }
action_install_homebrew_extended() { events+=(optional-install); return "${install_status:-0}"; }
workflow_selected_packages() {
  local -n test_packages_ref="$1"
  test_packages_ref=("${packages[@]}")
}

run_app() {
  actual=0
  setup_run || actual=$?
  [[ "$actual" == "$1" ]] || { printf 'App status: expected %s, got %s\n' "$1" "$actual" >&2; exit 1; }
}
assert_events() {
  [[ "${events[*]}" == "$1" ]] || { printf 'App events: %s\n' "${events[*]}" >&2; exit 1; }
}

SETUP_YOLO=0 SETUP_ADD_OPTIONALS=0
events=() answers=(restart start) answer_index=0
run_app 0
assert_events 'status.distribution_detected collect collect status.settings_confirmed run elapsed'

(
  events=() answers=(exit) answer_index=0
  run_app 0
  assert_events 'status.distribution_detected collect status.exited'
)
(
  events=() collect_status=7
  run_app 7
  assert_events 'status.distribution_detected collect'
)
(
  events=() answers=(start) answer_index=0 confirm_status=130
  run_app 130
  assert_events 'status.distribution_detected collect'
)
(
  events=() answers=(start) answer_index=0 runner_status=9
  run_app 9
  assert_events 'status.distribution_detected collect status.settings_confirmed run'
)
(
  events=() interactive_status=1
  run_app 1
  assert_events error.interactive_required
)
(
  events=() validation_status=1
  run_app 1
  assert_events error.config_invalid
)
(
  events=() environment_status=1
  run_app 1
  assert_events error.distribution_unsupported
)
(
  events=() SETUP_YOLO=1 interactive_status=1
  run_app 0
  assert_events 'status.distribution_detected status.yolo_mode status.yolo_skipped_optionals status.settings_confirmed run elapsed'
  workflow_selected selected fedora
  [[ "${selected[*]}" == 'native_packages zsh_default homebrew dotfiles' ]]
  workflow_selection optional_selection homebrew_extended
  [[ "$optional_selection" == no ]]
)

if ((EUID == 0)); then
  events=() SETUP_ADD_OPTIONALS=1
  run_app 1
  assert_events 'status.distribution_detected error.root_execution'
else
  (
    events=() SETUP_ADD_OPTIONALS=1 packages=(one)
    run_app 0
    assert_events 'status.distribution_detected optional-collect optional-install elapsed'
  )
  (
    events=() SETUP_ADD_OPTIONALS=1 packages=()
    run_app 0
    assert_events 'status.distribution_detected optional-collect status.optionals_none'
  )
  (
    events=() SETUP_ADD_OPTIONALS=1 packages=(one) brew_path=/missing/brew
    run_app 0
    assert_events 'status.distribution_detected brew-install optional-collect optional-install elapsed'
  )
  (
    events=() SETUP_ADD_OPTIONALS=1 brew_path=/missing/brew brew_choice=1
    run_app 1
    assert_events 'status.distribution_detected error.brew_not_installed'
  )
  (
    events=() SETUP_ADD_OPTIONALS=1 brew_path=/missing/brew input_status=130
    run_app 1
    assert_events 'status.distribution_detected error.input_interrupted'
  )
  (
    events=() SETUP_ADD_OPTIONALS=1 brew_path=/missing/brew brew_status=6
    run_app 6
    assert_events 'status.distribution_detected brew-install'
  )
  (
    events=() SETUP_ADD_OPTIONALS=1 optional_status=5
    run_app 5
    assert_events 'status.distribution_detected optional-collect'
  )
  (
    events=() SETUP_ADD_OPTIONALS=1 packages=(one) install_status=8
    run_app 8
    assert_events 'status.distribution_detected optional-collect optional-install'
  )
fi
printf 'Application scenario validation passed.\n'
