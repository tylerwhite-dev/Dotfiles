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

# Shares review/restart handling; optional mode prepares Homebrew separately.
_app_run() {
  local platform="$1" distribution_name="$2" mode=all started_at text
  local action confirmation_status brew_bin need_brew=no requirement choice prompt yes_option no_option
  local collect_answers=yes
  local -a selected=() approved_requirements=()
  [[ "${SETUP_MODE:-standard}" != optionals ]] || mode=optionals
  if [[ "$mode" == optionals ]] && ((EUID == 0)); then
    error_report error.root_execution
    return 1
  fi
  while true; do
    if [[ "$collect_answers" == yes ]]; then
      if [[ "$mode" == optionals ]]; then
        questionnaire_collect_optionals "$platform" "$distribution_name" || return
      else
        questionnaire_collect "$platform" "$distribution_name" || return
      fi
      collect_answers=no
    fi
    if [[ "$mode" == optionals ]]; then
      workflow_selected_optionals selected "$platform"
      if ((${#selected[@]} == 0)); then
        status_report status.optionals_none
        return 0
      fi
    fi
    questionnaire_confirm action "$platform" "$distribution_name" "$mode" || return
    case "$action" in
      restart) collect_answers=yes; continue ;;
      exit)
        if [[ "$mode" == optionals ]]; then
          status_report status.exited
        else
          message_format text status.exited
          ui_success "$text"
        fi
        return 0 ;;
    esac
    confirmation_status=0
    questionnaire_confirm_requirements approved_requirements "$platform" "$mode" || confirmation_status=$?
    case "$confirmation_status" in
      0) ;;
      2) continue ;;
      3) collect_answers=yes; continue ;;
      4) status_report status.exited; return 0 ;;
      *) return "$confirmation_status" ;;
    esac
    if [[ "$mode" == optionals ]]; then
      need_brew=no
      for choice in "${selected[@]}"; do
        catalog_requirement requirement "$choice"
        if [[ "$requirement" == homebrew ]]; then need_brew=yes; break; fi
      done
      brew_bin="$(executor_brew_bin)"
      if [[ "$need_brew" == yes && ! -x "$brew_bin" ]]; then
        message_format prompt prompt.brew_install
        message_format yes_option option.yes
        message_format no_option option.no
        if ! ui_select choice "$prompt" "" 0 minimal "$yes_option" "$no_option"; then
          error_report error.input_interrupted
          return 1
        fi
        if ((choice != 0)); then collect_answers=yes; continue; fi
      fi
    fi
    break
  done
  started_at="$SECONDS"
  if [[ "$mode" == optionals ]]; then
    status_report status.settings_confirmed
  else
    message_format text status.settings_confirmed
    ui_success "$text"
  fi
  runner_install_native_requirements "$platform" "${approved_requirements[@]}" || return
  if [[ "$mode" == optionals ]]; then
    if [[ "$need_brew" == yes && ! -x "$brew_bin" ]]; then
      status_report status.optionals_brew_prepare
      if [[ "$platform" == macos ]] && catalog_is_enabled macos_command_line_tools; then
        action_prepare_macos_command_line_tools "$platform" || return
        action_install_macos_command_line_tools "$platform" || return
      fi
      action_install_homebrew "$platform" "$SETUP_REPOSITORY_ROOT" || return
    fi
    runner_run_optionals "$platform" "$distribution_name" "$SETUP_REPOSITORY_ROOT" || return
  else
    runner_run "$platform" "$distribution_name" "$SETUP_REPOSITORY_ROOT" || return
  fi
  _app_print_elapsed_time "$((SECONDS - started_at))"
}

# Validates the environment, then dispatches to the requested scenario.
setup_run() {
  local distribution_family distribution_name text

  if ! ui_is_interactive; then
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
  if ! environment_scenario_matches "${SETUP_MODE:-standard}" "$distribution_family"; then
    error_report error.scenario_mismatch "$SETUP_MODE" "$distribution_name"
    return 1
  fi
  message_format text status.distribution_detected "$distribution_name"
  ui_success "$text"
  ui_ansi_palette
  _app_run "$distribution_family" "$distribution_name"
}
