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

# Runs validation, detection, questionnaire, confirmation, and execution flow.
setup_run() {
  local started_at
  local distribution_family
  local distribution_name
  local status_message
  local action
  local -a yolo_available=()
  local procedure_id

  if [[ "${SETUP_YOLO:-0}" != "1" ]] && ! ui_is_interactive; then
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

  message_format status_message status.distribution_detected "$distribution_name"
  ui_success "$status_message"
  ui_ansi_palette

  if [[ "${SETUP_YOLO:-0}" == "1" ]]; then
    message_format status_message status.yolo_mode
    ui_notice "$status_message"
    workflow_reset
    workflow_available yolo_available "$distribution_family"
    for procedure_id in "${yolo_available[@]}"; do
      workflow_select "$procedure_id" yes
    done
    action="start"
  else
    while true; do
      questionnaire_collect "$distribution_family" "$distribution_name" || return
      questionnaire_confirm action "$distribution_family" "$distribution_name" || return

      case "$action" in
        start) break ;;
        restart) continue ;;
        exit)
          message_format status_message status.exited
          ui_success "$status_message"
          return 0
          ;;
      esac
    done
  fi

  started_at="$SECONDS"
  message_format status_message status.settings_confirmed
  ui_success "$status_message"
  runner_run \
    "$distribution_family" "$distribution_name" "$SETUP_REPOSITORY_ROOT" || return
  _app_print_elapsed_time "$((SECONDS - started_at))"
}
