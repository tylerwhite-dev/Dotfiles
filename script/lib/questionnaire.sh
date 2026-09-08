#!/usr/bin/env bash

questionnaire_print_stage_heading() {
  local available_count="$1"

  printf '\n%sSYSTEM SETUP%s\n' \
    "$ui_color_execution_heading" "$ui_color_reset"
  printf '%s%s%s\n' \
    "$ui_color_execution_heading" \
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' \
    "$ui_color_reset"
  printf '%s%s · %d steps available%s\n\n' \
    "$ui_color_hint" "$distribution_name" "$available_count" "$ui_color_reset"
}

questionnaire_format_comment() {
  local comment="$1"
  local line
  local formatted=""

  while IFS= read -r line; do
    if [[ -n "$formatted" ]]; then
      formatted+=$'\n'
    fi

    if [[ "$line" == "  "* ]]; then
      formatted+="${ui_color_package}${line}${ui_color_comment}"
    elif [[ -n "$line" ]]; then
      formatted+="  ${line}"
    else
      formatted+=''
    fi
  done <<< "$comment"

  STEP_RENDERED_COMMENT="$formatted"
}

questionnaire_read_step() {
  local step_id="$1"
  local current="$2"
  local total="$3"
  local prompt

  steps_render_comment "$step_id" "$distribution_family"
  questionnaire_format_comment "$STEP_RENDERED_COMMENT"
  printf -v prompt '◉  %02d / %02d  %s' \
    "$current" "$total" "${STEP_QUESTION[$step_id]}"

  ui_select \
    "$prompt" \
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
  local available_count=0
  local current=0

  steps_reset_answers

  for step_id in "${STEP_IDS[@]}"; do
    if steps_is_available "$step_id" "$distribution_family"; then
      ((available_count += 1))
    fi
  done

  questionnaire_print_stage_heading "$available_count"
  ui_menu_style="minimal"

  for step_id in "${STEP_IDS[@]}"; do
    if ! steps_is_available "$step_id" "$distribution_family"; then
      continue
    fi

    if ! steps_requirement_is_selected "$step_id"; then
      continue
    fi

    ((current += 1))
    questionnaire_read_step "$step_id" "$current" "$available_count"
  done

  ui_menu_style="default"
}

questionnaire_show_summary() {
  local step_id
  local description
  local symbol
  local symbol_color

  printf '\n%sREVIEW SELECTION%s\n' \
    "$ui_color_execution_heading" "$ui_color_reset"
  printf '%s%s%s\n' \
    "$ui_color_execution_heading" \
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' \
    "$ui_color_reset"
  printf '%s%s · selected setup steps%s\n\n' \
    "$ui_color_hint" "$distribution_name" "$ui_color_reset"

  for step_id in "${STEP_IDS[@]}"; do
    if ! steps_is_available "$step_id" "$distribution_family"; then
      continue
    fi

    description="${STEP_QUESTION[$step_id]%\?}"
    if [[ "${STEP_SELECTED[$step_id]}" == "yes" ]]; then
      symbol='●'
      symbol_color="$ui_color_success"
    else
      symbol='○'
      symbol_color="$ui_color_hint"
    fi

    printf '%s%s%s  %s  %s\n' \
      "$symbol_color" "$symbol" "$ui_color_reset" \
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
