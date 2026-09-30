#!/usr/bin/env bash

# Draws all menu options while reserving space for the active marker.
_ui_draw_menu_options() {
  local __ui_draw_selected="$1"
  shift
  local __ui_draw_index __ui_draw_label __ui_draw_columns="${COLUMNS:-80}"
  local -a __ui_draw_options=("$@")
  [[ "$__ui_draw_columns" =~ ^[1-9][0-9]*$ ]] || __ui_draw_columns=80
  local __ui_draw_width=$((10#$__ui_draw_columns-7))
  ((__ui_draw_width < 1)) && __ui_draw_width=1
  for ((__ui_draw_index=0; __ui_draw_index<${#__ui_draw_options[@]}; __ui_draw_index++)); do
    _ui_truncate __ui_draw_label "${__ui_draw_options[__ui_draw_index]}" "$__ui_draw_width"
    if ((__ui_draw_index == __ui_draw_selected)); then
      printf '\r\033[2K    %s› %s%s\n' "$ui_color_selected" "$__ui_draw_label" "$ui_color_reset"
    else
      printf '\r\033[2K      %s\n' "$__ui_draw_label"
    fi
  done
}

# Reads normalized events, applies single-choice navigation, and redraws options.
_ui_read_menu_choice() {
  local __ui_choice_result="$1" __ui_choice_cursor="$2"
  shift 2
  local -a __ui_choice_options=("$@")
  local __ui_choice_count="${#__ui_choice_options[@]}" __ui_choice_key
  while true; do
    _ui_read_key __ui_choice_key || return
    case "$__ui_choice_key" in
      enter) printf -v "$__ui_choice_result" '%d' "$__ui_choice_cursor"; return 0 ;;
      up) __ui_choice_cursor=$(((__ui_choice_cursor-1+__ui_choice_count)%__ui_choice_count)) ;;
      down) __ui_choice_cursor=$(((__ui_choice_cursor+1)%__ui_choice_count)) ;;
      *) continue ;;
    esac
    printf '\033[%dA' "$__ui_choice_count"
    _ui_draw_menu_options "$__ui_choice_cursor" "${__ui_choice_options[@]}"
  done
}

# Renders a menu and returns its index; caller output names must not use __ui_.
ui_select() {
  _ui_output_name "$1" || return
  local __ui_select_result="$1" __ui_select_prompt="$2" __ui_select_detail="$3"
  local __ui_select_default="$4" __ui_select_style="$5"
  shift 5
  local -a __ui_select_options=("$@")
  local __ui_select_count="${#__ui_select_options[@]}" __ui_select_choice
  if ((__ui_select_count == 0 || __ui_select_default < 0 || __ui_select_default >= __ui_select_count)); then
    return 2
  fi
  if [[ "$__ui_select_style" == minimal ]]; then
    printf '\n'
  else
    printf '\n%s%s%s\n' "$ui_color_heading" \
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' "$ui_color_reset"
  fi
  printf '%s%s%s\n' "$ui_color_question" "$__ui_select_prompt" "$ui_color_reset"
  [[ -z "$__ui_select_detail" ]] || _ui_print_detail "$__ui_select_detail"
  printf '\n'
  _ui_draw_menu_options "$__ui_select_default" "${__ui_select_options[@]}"
  _ui_read_menu_choice __ui_select_choice "$__ui_select_default" "${__ui_select_options[@]}" || return
  printf -v "$__ui_select_result" '%d' "$__ui_select_choice"
}
