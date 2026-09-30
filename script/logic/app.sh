#!/usr/bin/env bash

# Formats and prints the elapsed execution time in minutes or seconds.
_app_print_elapsed_time() {
  local elapsed_seconds="$1"
  local elapsed_minutes=$((elapsed_seconds / 60))
  local remaining_seconds=$((elapsed_seconds % 60))
  local message

  if ((elapsed_minutes > 0)); then
    message_format message status.elapsed.minutes \
      "$elapsed_minutes" "$remaining_seconds"
  else
    message_format message status.elapsed.seconds "$remaining_seconds"
  fi

  ui_notice ""
  ui_heading_line "$message"
}

# Runs the optionals-only scenario without entering the normal runner.
_app_run_optionals() {
  local platform="$1" distribution_name="$2" started_at="$SECONDS"
  local brew_bin prompt yes_option no_option choice
  local -a selected=()

  if ((EUID == 0)); then
    error_report error.root_execution
    return 1
  fi
  brew_bin="$(executor_brew_bin)"
  if [[ ! -x "$brew_bin" ]]; then
    message_format prompt prompt.brew_install
    message_format yes_option option.yes
    message_format no_option option.no
    if ! ui_select choice "$prompt" "" 0 minimal "$yes_option" "$no_option"; then
      error_report error.input_interrupted
      return 1
    fi
    if ((choice != 0)); then
      error_report error.brew_not_installed
      return 1
    fi
    action_install_homebrew_binary || return
  fi
  questionnaire_collect_optionals "$platform" "$distribution_name" || return
  workflow_selected_packages selected homebrew_extended
  if ((${#selected[@]} == 0)); then
    status_report status.optionals_none
    return 0
  fi
  action_install_homebrew_extended "$platform" || return
  _app_print_elapsed_time "$((SECONDS - started_at))"
}

# Records every available non-selectable procedure for the YOLO scenario.
_app_collect_yolo_selection() {
  local platform="$1" procedure_id is_selectable label skipped_list text
  local -a available=() skipped=()

  message_format text status.yolo_mode
  ui_notice "$text"
  workflow_reset
  workflow_available available "$platform"
  for procedure_id in "${available[@]}"; do
    catalog_is_selectable is_selectable "$procedure_id"
    if [[ "$is_selectable" == yes ]]; then
      message_format label "procedure.${procedure_id}.label"
      skipped+=("$label")
      continue
    fi
    workflow_select "$procedure_id" yes
  done
  if ((${#skipped[@]} > 0)); then
    skipped_list="$(IFS=', '; printf '%s' "${skipped[*]}")"
    message_format text status.yolo_skipped_optionals "$skipped_list"
    ui_notice "$text"
  fi
  return 0
}

# Keeps restart/exit handling separate from execution and YOLO selection.
_app_run_standard() {
  local platform="$1" distribution_name="$2" action text started_at

  if [[ "${SETUP_YOLO:-0}" == 1 ]]; then
    _app_collect_yolo_selection "$platform" || return
  else
    while true; do
      questionnaire_collect "$platform" "$distribution_name" || return
      questionnaire_confirm action "$platform" "$distribution_name" || return
      case "$action" in
        start) break ;;
        restart) continue ;;
        exit)
          message_format text status.exited
          ui_success "$text"
          return 0
          ;;
      esac
    done
  fi
  started_at="$SECONDS"
  message_format text status.settings_confirmed
  ui_success "$text"
  runner_run "$platform" "$distribution_name" "$SETUP_REPOSITORY_ROOT" || return
  _app_print_elapsed_time "$((SECONDS - started_at))"
}

# Validates the environment, then dispatches to the requested scenario.
setup_run() {
  local distribution_family distribution_name text

  if [[ "${SETUP_YOLO:-0}" != 1 ]] && ! ui_is_interactive; then
    error_report error.interactive_required
    return 1
  fi
  if ! catalog_validate; then
    error_report error.config_invalid
    return 1
  fi
  if ! environment_detect distribution_family distribution_name; then
    error_report error.distribution_unsupported
    return 1
  fi
  message_format text status.distribution_detected "$distribution_name"
  ui_success "$text"
  ui_ansi_palette
  if [[ "${SETUP_ADD_OPTIONALS:-0}" == 1 ]]; then
    _app_run_optionals "$distribution_family" "$distribution_name"
  else
    _app_run_standard "$distribution_family" "$distribution_name"
  fi
}
