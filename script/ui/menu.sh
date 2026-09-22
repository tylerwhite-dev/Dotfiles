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
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' \
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

# Draws a checkbox list, highlighting the focused row and marking checked items.
_ui_draw_multiselect_options() {
  local cursor_index="$1"
  shift
  local -n marked_ref="$1"
  shift

  local options=("$@")
  local index
  local mark
  local mark_color

  for ((index = 0; index < ${#options[@]}; index++)); do
    if [[ "${marked_ref[$index]:-0}" == "1" ]]; then
      mark='[x]'
      mark_color="$ui_color_success"
    else
      mark='[ ]'
      mark_color="$ui_color_hint"
    fi

    printf '\r\033[2K'
    if ((index == cursor_index)); then
      printf '    %s› %s %s %s%s\n' \
        "$ui_color_selected" "$mark" "${options[index]}" "$mark_color" "$ui_color_reset"
    else
      printf '      %s %s%s\n' "$mark" "${options[index]}" "$ui_color_reset"
    fi
  done
}

# Draws the selected-items count line for a checkbox list.
_ui_draw_multiselect_count() {
  local -n marked_ref="$1"
  local option_count="$2"
  local count=0
  local i

  for ((i = 1; i < option_count; i++)); do
    if [[ "${marked_ref[$i]:-0}" == "1" ]]; then
      ((count++))
    fi
  done

  printf '\r\033[2K'
  if ((count > 0)); then
    printf '    %s%d items selected%s\n' "$ui_color_hint" "$count" "$ui_color_reset"
  else
    printf '    %sNo items selected%s\n' "$ui_color_hint" "$ui_color_reset"
  fi
  printf '\n'
}

# Reads navigation (arrows), toggle (Space), and confirm (Enter) for checkboxes.
# Takes the canonical marked-variable name so redraws never pass a nameref alias.
_ui_read_multiselect_choice() {
  local cursor_index="$1"
  local option_count="$2"
  local marked_name="$3"
  shift 3
  local -n marked_ref="$marked_name"

  local options=("$@")
  local key=""
  local escape_sequence=""

  while true; do
    key=""
    if ! IFS= read -rsn1 key; then
      return 130
    fi

    case "$key" in
      " ")
        marked_ref[$cursor_index]=$((1 - ${marked_ref[$cursor_index]:-0}))
        if ((cursor_index == 0)); then
          local all_state="${marked_ref[0]}"
          for ((i = 1; i < option_count; i++)); do
            marked_ref[$i]="$all_state"
          done
        else
          local all_on=1
          for ((i = 1; i < option_count; i++)); do
            if [[ "${marked_ref[$i]:-0}" != "1" ]]; then
              all_on=0
              break
            fi
          done
          marked_ref[0]="$all_on"
        fi
        printf '\033[%dA' "$((option_count + 2))"
        _ui_draw_multiselect_count "$marked_name" "$option_count"
        _ui_draw_multiselect_options "$cursor_index" "$marked_name" "${options[@]}"
        ;;
      "" )
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

          printf '\033[%dA' "$((option_count + 2))"
          _ui_draw_multiselect_count "$marked_name" "$option_count"
          _ui_draw_multiselect_options "$cursor_index" "$marked_name" "${options[@]}"
        fi
        ;;
    esac
  done
}

# Renders a checkbox list and returns the names of the checked items.
ui_multiselect() {
  local result_name="$1"
  local prompt="$2"
  shift 2

  local -a options=("All" "$@")
  local option_count="${#options[@]}"
  local -A marked=()
  local index
  local -a checked_items=()

  if ((${#options[@]} <= 1)); then
    return 2
  fi

  printf '\n%s%s%s\n' \
    "$ui_color_heading" \
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' \
    "$ui_color_reset"
  printf '%s%s%s\n' "$ui_color_question" "$prompt" "$ui_color_reset"
  printf '%s  ↓ move  ·  Space toggle  ·  Enter confirm%s\n' \
    "$ui_color_hint" "$ui_color_reset"

  printf '\n'
  _ui_draw_multiselect_count marked "$option_count"
  _ui_draw_multiselect_options 0 marked "${options[@]}"
  _ui_read_multiselect_choice 0 "$option_count" marked "${options[@]}" || return

  for index in "${!marked[@]}"; do
    if ((index == 0)); then continue; fi
    if [[ "${marked[$index]}" == "1" ]]; then
      checked_items+=("${options[index]}")
    fi
  done

  local -n result_ref="$result_name"
  result_ref=("${checked_items[@]}")
}
