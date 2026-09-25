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
  local brew_prompt
  local brew_yes_option
  local brew_no_option
  local brew_selected_index
  local brew_bin
  local -a selected_optionals=()
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

  if [[ "${SETUP_ADD_OPTIONALS:-0}" == "1" ]]; then
    started_at="$SECONDS"
    if ((EUID == 0)); then
      error_report error.root_execution
      return 1
    fi

    brew_bin="$(executor_brew_bin)"
    if [[ ! -x "$brew_bin" ]]; then
      message_format brew_prompt prompt.brew_install
      message_format brew_yes_option option.yes
      message_format brew_no_option option.no
      if ! ui_select brew_selected_index "$brew_prompt" "" 0 minimal \
        "$brew_yes_option" "$brew_no_option"; then
        error_report error.input_interrupted
        return 1
      fi
      if ((brew_selected_index != 0)); then
        error_report error.brew_not_installed
        return 1
      fi
      _action_install_homebrew_binary || return
    fi

    questionnaire_collect_optionals \
      "$distribution_family" "$distribution_name" || return
    workflow_selected_packages selected_optionals homebrew_extended
    if ((${#selected_optionals[@]} == 0)); then
      status_report status.optionals_none
      return 0
    fi
    action_install_homebrew_extended "$distribution_family" || return

    _app_print_elapsed_time "$((SECONDS - started_at))"
    return 0
  fi

  if [[ "${SETUP_YOLO:-0}" == "1" ]]; then
    message_format status_message status.yolo_mode
    ui_notice "$status_message"
    workflow_reset
    workflow_available yolo_available "$distribution_family"
    for procedure_id in "${yolo_available[@]}"; do
      local is_selectable
      catalog_is_selectable is_selectable "$procedure_id"
      if [[ "$is_selectable" == "yes" ]]; then
        workflow_select_packages_all "$procedure_id" "$distribution_family" || return
      else
        workflow_select "$procedure_id" yes
      fi
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
