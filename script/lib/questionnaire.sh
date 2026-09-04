#!/usr/bin/env bash

questionnaire_read_step() {
  local step_id="$1"

  steps_render_comment "$step_id" "$distribution_family"
  ui_select \
    "${STEP_QUESTION[$step_id]}" \
    "$STEP_RENDERED_COMMENT" \
    0 \
    "Yes" \
    "No"

  if ((UI_SELECTED_INDEX == 0)); then
    STEP_SELECTED["$step_id"]="yes"
  else
    STEP_SELECTED["$step_id"]="no"
  fi
}

questionnaire_collect_answers() {
  local step_id

  steps_reset_answers

  for step_id in "${STEP_IDS[@]}"; do
    if ! steps_is_available "$step_id" "$distribution_family"; then
      continue
    fi

    if ! steps_requirement_is_selected "$step_id"; then
      continue
    fi

    questionnaire_read_step "$step_id"
  done
}

questionnaire_show_summary() {
  local step_id
  local description

  ui_print_separator
  ui_print_heading "The following settings will be applied:"
  printf '\nDistribution: %s\n' "$distribution_name"

  for step_id in "${STEP_IDS[@]}"; do
    if ! steps_is_available "$step_id" "$distribution_family"; then
      continue
    fi

    description="${STEP_QUESTION[$step_id]%\?}"
    printf '%s: %s\n' \
      "$description" \
      "$(ui_yes_no_label "${STEP_SELECTED[$step_id]}")"
  done
}

questionnaire_confirm_answers() {
  questionnaire_show_summary
  ui_select \
    "Choose an action:" \
    "" \
    0 \
    "Start execution" \
    "Restart questionnaire" \
    "Exit without changes"

  case "$UI_SELECTED_INDEX" in
    0)
      return 0
      ;;
    1)
      return 1
      ;;
    2)
      ui_print_success "Exited without changes."
      exit 0
      ;;
  esac
}
