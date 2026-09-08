#!/usr/bin/env bash

# Draws all menu options while reserving space for the active marker.
_ui_draw_menu_options() {
  local selected_index="$1"
  shift

  local options=("$@")
  local index

  for ((index = 0; index < ${#options[@]}; index++)); do
    printf '\r\033[2K'
    if ((index == selected_index)); then
      printf '    %s› %s%s\n' \
        "$ui_color_selected" "${options[index]}" "$ui_color_reset"
    else
      printf '      %s\n' "${options[index]}"
    fi
  done
}

# Reads Enter or arrow-key input and returns the chosen menu index.
_ui_read_menu_choice() {
  local result_name="$1"
  local cursor_index="$2"
  shift 2

  local options=("$@")
  local option_count="${#options[@]}"
  local key=""
  local escape_sequence=""

  while true; do
    key=""
    if ! IFS= read -rsn1 key; then
      return 130
    fi

    case "$key" in
      "")
        printf -v "$result_name" '%d' "$cursor_index"
        return 0
        ;;
      $'\033')
        escape_sequence=""
        if IFS= read -rsn2 -t 0.2 escape_sequence; then
          case "$escape_sequence" in
            '[A' | 'OA')
              cursor_index=$(((cursor_index - 1 + option_count) % option_count))
              ;;
            '[B' | 'OB')
              cursor_index=$(((cursor_index + 1) % option_count))
              ;;
            *)
              continue
              ;;
          esac

          printf '\033[%dA' "$option_count"
          _ui_draw_menu_options "$cursor_index" "${options[@]}"
        fi
        ;;
    esac
  done
}

# Renders a menu, handles keyboard navigation, and returns the selected index.
ui_select() {
  local result_name="$1"
  local prompt="$2"
  local detail="$3"
  local default_index="$4"
  local style="$5"
  shift 5

  local options=("$@")
  local option_count="${#options[@]}"
  local choice_value

  if ((option_count == 0 || default_index < 0 || default_index >= option_count)); then
    return 2
  fi

  if [[ "$style" == "minimal" ]]; then
    printf '\n'
  else
    printf '\n%s%s%s\n' \
      "$ui_color_heading" \
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' \
      "$ui_color_reset"
  fi

  printf '%s%s%s\n' "$ui_color_question" "$prompt" "$ui_color_reset"
  if [[ -n "$detail" ]]; then
    _ui_print_detail "$detail"
  fi

  printf '\n'
  _ui_draw_menu_options "$default_index" "${options[@]}"
  _ui_read_menu_choice choice_value "$default_index" "${options[@]}" || return
  printf -v "$result_name" '%d' "$choice_value"
}
