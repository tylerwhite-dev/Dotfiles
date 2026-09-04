#!/usr/bin/env bash

ui_color_reset=""
ui_color_heading=""
ui_color_execution_heading=""
ui_color_question=""
ui_color_separator=""
ui_color_success=""
ui_color_error=""
ui_color_hint=""
ui_color_comment=""
ui_color_selected=""

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  ui_color_reset=$'\033[0m'
  ui_color_heading=$'\033[1;35m'
  ui_color_execution_heading=$'\033[1;34m'
  ui_color_question=$'\033[1;36m'
  ui_color_separator=$'\033[2;34m'
  ui_color_success=$'\033[1;32m'
  ui_color_error=$'\033[1;31m'
  ui_color_hint=$'\033[2m'
  ui_color_comment=$'\033[0;33m'
  ui_color_selected=$'\033[1;30;46m'
fi

UI_SELECTED_INDEX=0
ui_menu_help_shown="no"

ui_is_interactive() {
  [[ -t 0 && -t 1 ]]
}

ui_print_separator() {
  printf '\n%s%s%s\n' \
    "$ui_color_separator" \
    '------------------------------------------------------------' \
    "$ui_color_reset"
}

ui_print_heading() {
  printf '%s%s%s\n' "$ui_color_heading" "$1" "$ui_color_reset"
}

ui_print_execution_heading() {
  printf '%s%s%s\n' \
    "$ui_color_execution_heading" "$1" "$ui_color_reset"
}

ui_print_success() {
  printf '\n%s%s%s\n' "$ui_color_success" "$1" "$ui_color_reset"
}

ui_print_error() {
  printf '\n%s%s%s\n' "$ui_color_error" "$1" "$ui_color_reset" >&2
}

ui_yes_no_label() {
  if [[ "$1" == "yes" ]]; then
    printf '%syes%s' "$ui_color_success" "$ui_color_reset"
  else
    printf '%sno%s' "$ui_color_error" "$ui_color_reset"
  fi
}

ui_draw_menu_options() {
  local selected_index="$1"
  shift

  local options=("$@")
  local index

  for ((index = 0; index < ${#options[@]}; index++)); do
    printf '\r\033[2K'

    if ((index == selected_index)); then
      printf '%s  > %s  %s\n' \
        "$ui_color_selected" "${options[index]}" "$ui_color_reset"
    else
      printf '    %s\n' "${options[index]}"
    fi
  done
}

ui_select() {
  local prompt="$1"
  local comment="$2"
  local selected_index="$3"
  shift 3

  local options=("$@")
  local option_count="${#options[@]}"
  local key=""
  local escape_sequence=""

  if ((option_count == 0 || selected_index < 0 || selected_index >= option_count)); then
    ui_print_error "The menu is configured incorrectly."
    return 2
  fi

  ui_print_separator
  printf '%s%s%s\n' "$ui_color_question" "$prompt" "$ui_color_reset"

  if [[ -n "$comment" ]]; then
    printf '%s%s%s\n' "$ui_color_comment" "$comment" "$ui_color_reset"
  fi

  if [[ "$ui_menu_help_shown" == "no" ]]; then
    printf '%sUse Up and Down to move. Press Enter to confirm.%s\n' \
      "$ui_color_hint" "$ui_color_reset"
    ui_menu_help_shown="yes"
  fi

  printf '\n'
  ui_draw_menu_options "$selected_index" "${options[@]}"

  while true; do
    key=""

    if ! IFS= read -rsn1 key; then
      ui_print_error "Input was interrupted. No changes were applied."
      exit 1
    fi

    case "$key" in
      "")
        UI_SELECTED_INDEX="$selected_index"
        return 0
        ;;
      $'\033')
        escape_sequence=""

        if IFS= read -rsn2 -t 0.2 escape_sequence; then
          case "$escape_sequence" in
            '[A' | 'OA')
              selected_index=$(((selected_index - 1 + option_count) % option_count))
              ;;
            '[B' | 'OB')
              selected_index=$(((selected_index + 1) % option_count))
              ;;
            *)
              continue
              ;;
          esac

          printf '\033[%dA' "$option_count"
          ui_draw_menu_options "$selected_index" "${options[@]}"
        fi
        ;;
    esac
  done
}
