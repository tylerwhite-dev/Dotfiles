#!/usr/bin/env bash

# Retrieves one of a procedure's configured question, label, or description.
_questionnaire_procedure_text() {
  local result_name="$1"
  local procedure_id="$2"
  local text_kind="$3"

  message_format "$result_name" "procedure.${procedure_id}.${text_kind}"
}

# Collects the package selections for a selectable procedure via checkboxes.
_questionnaire_read_selectable_packages() {
  local procedure_id="$1"
  local platform="$2"
  local current="$3"
  local total="$4"
  local question
  local description
  local prompt
  local -a packages=()
  local -a selected=()

  _questionnaire_procedure_text question "$procedure_id" question
  _questionnaire_procedure_text description "$procedure_id" description
  message_format prompt question.progress "$current" "$total" "$question"
  catalog_packages packages "$procedure_id" "$platform" brew || return

  if ! ui_multiselect selected "$prompt" "${packages[@]}"; then
    error_report error.input_interrupted
    return 1
  fi

  workflow_select_packages "$procedure_id" "${selected[@]}"
  if ((${#selected[@]} > 0)); then
    workflow_select "$procedure_id" yes
  else
    workflow_select "$procedure_id" no
  fi
}

# Renders and records one procedure's yes/no answer.
_questionnaire_read_procedure() {
  local procedure_id="$1"
  local platform="$2"
  local current="$3"
  local total="$4"
  local question
  local description
  local prompt
  local detail
  local yes_option
  local no_option
  local selected_index
  local is_selectable
  local -a packages=()

  catalog_is_selectable is_selectable "$procedure_id"
  if [[ "$is_selectable" == "yes" ]]; then
    _questionnaire_read_selectable_packages \
      "$procedure_id" "$platform" "$current" "$total" || return
    return 0
  fi

  _questionnaire_procedure_text question "$procedure_id" question
  _questionnaire_procedure_text description "$procedure_id" description
  message_format prompt question.progress "$current" "$total" "$question"
  message_format yes_option option.yes
  message_format no_option option.no
  catalog_packages packages "$procedure_id" "$platform"
  ui_detail detail "$description" "${packages[@]}"

  if ! ui_select selected_index "$prompt" "$detail" 0 minimal \
    "$yes_option" "$no_option"; then
    error_report error.input_interrupted
    return 1
  fi

  if ((selected_index == 0)); then
    workflow_select "$procedure_id" yes
  else
    workflow_select "$procedure_id" no
  fi
}

# Resets workflow state and collects answers for all available procedures.
questionnaire_collect() {
  local platform="$1"
  local distribution_name="$2"
  local title
  local metadata
  local procedure_id
  local current=0
  local -a available=()

  workflow_reset
  workflow_available available "$platform"
  message_format title stage.questionnaire.title
  message_format metadata stage.questionnaire.meta \
    "$distribution_name" "${#available[@]}"
  ui_stage "$title" "$metadata"

  for procedure_id in "${available[@]}"; do
    ((current += 1))
    if ! workflow_requirement_is_selected "$procedure_id"; then
      continue
    fi

    _questionnaire_read_procedure \
      "$procedure_id" "$platform" "$current" "${#available[@]}" || return
  done
}

# Collects only the package choices for the first selectable procedure
# (used by --add-optionals).
questionnaire_collect_optionals() {
  local platform="$1"
  local distribution_name="$2"
  local title
  local metadata
  local procedure_id
  local is_selectable
  local current=0
  local -a available=()

  workflow_reset
  workflow_available available "$platform"

  for procedure_id in "${available[@]}"; do
    ((current += 1))
    catalog_is_selectable is_selectable "$procedure_id"
    if [[ "$is_selectable" == "yes" ]]; then
      message_format title stage.questionnaire.title
      message_format metadata stage.questionnaire.meta \
        "$distribution_name" "${#available[@]}"
      ui_stage "$title" "$metadata"
      _questionnaire_read_selectable_packages \
        "$procedure_id" "$platform" "$current" "${#available[@]}" || return
      return 0
    fi
  done

  status_report status.optionals_none
  return 0
}

# Displays the review rows for all procedures available on the platform.
_questionnaire_show_summary() {
  local platform="$1"
  local distribution_name="$2"
  local title
  local metadata
  local yes_label
  local no_label
  local procedure_id
  local label
  local selection
  local -a available=()

  workflow_available available "$platform"
  message_format title stage.review.title
  message_format metadata stage.review.meta "$distribution_name"
  message_format yes_label label.yes
  message_format no_label label.no
  ui_stage "$title" "$metadata"

  for procedure_id in "${available[@]}"; do
    _questionnaire_procedure_text label "$procedure_id" label

    local is_selectable
    catalog_is_selectable is_selectable "$procedure_id"
    if [[ "$is_selectable" == "yes" ]]; then
      local -a packages=()
      local -a all_packages=()
      local status
      workflow_selected_packages packages "$procedure_id"
      catalog_packages all_packages "$procedure_id" "$platform" brew
      if ((${#packages[@]} == ${#all_packages[@]})) && ((${#packages[@]} > 0)); then
        message_format status status.all_packages_selected
      elif ((${#packages[@]} > 0)); then
        message_format status status.selected_count "${#packages[@]}"
      else
        message_format status status.no_packages_selected
      fi
      ui_summary_item_packages "$label" "${#packages[@]}" "$status"
    else
      workflow_selection selection "$procedure_id"
      ui_summary_item "$label" "$selection" "$yes_label" "$no_label"
    fi
  done
}

# Lets the user start, restart, or exit after reviewing selections.
questionnaire_confirm() {
  local result_name="$1"
  local platform="$2"
  local distribution_name="$3"
  local prompt
  local start_option
  local restart_option
  local exit_option
  local selected_index

  _questionnaire_show_summary "$platform" "$distribution_name"
  message_format prompt prompt.action
  message_format start_option option.start
  message_format restart_option option.restart
  message_format exit_option option.exit

  if ! ui_select selected_index "$prompt" "" 0 minimal \
    "$start_option" "$restart_option" "$exit_option"; then
    error_report error.input_interrupted
    return 1
  fi

  case "$selected_index" in
    0) printf -v "$result_name" '%s' start ;;
    1) printf -v "$result_name" '%s' restart ;;
    2) printf -v "$result_name" '%s' exit ;;
  esac
}
