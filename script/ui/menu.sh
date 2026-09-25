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
# A group row owns the item rows that follow it up to the next group row and is
# preceded by a blank line when it is not the first group.
_ui_draw_multiselect_options() {
  local cursor_index="$1"
  local kinds_name="$2"
  local marked_name="$3"
  shift 3
  local -n kinds_ref="$kinds_name"
  local -n marked_ref="$marked_name"

  local options=("$@")
  local index
  local kind
  local mark
  local mark_color
  local group_state
  local seen_group="no"

  for ((index = 0; index < ${#options[@]}; index++)); do
    kind="${kinds_ref[index]:-i}"

    if [[ "$kind" == "g" ]]; then
      if [[ "$seen_group" == "yes" ]]; then
        printf '\r\033[2K\n'
      fi
      seen_group="yes"
      _ui_multiselect_group_state "$kinds_name" "$marked_name" "$index" group_state
      case "$group_state" in
        full)
          mark='[x]'
          mark_color="$ui_color_success"
          ;;
        partial)
          mark='[-]'
          mark_color="$ui_color_selected"
          ;;
        *)
          mark='[ ]'
          mark_color="$ui_color_hint"
          ;;
      esac

      printf '\r\033[2K'
      if ((index == cursor_index)); then
        printf '    %s› %s %s%s%s%s\n' \
          "$ui_color_selected" "$mark" "$mark_color" \
          "$ui_color_group" "${options[index]}" "$ui_color_reset"
      else
        printf '      %s %s%s%s%s\n' \
          "$mark" "$mark_color" "$ui_color_group" "${options[index]}" \
          "$ui_color_reset"
      fi
      continue
    fi

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

# Reports a group row as full, partial, or empty. The state is derived from the
# group items instead of being stored, so a group row and its items can never
# disagree.
_ui_multiselect_group_state() {
  local kinds_name="$1"
  local marked_name="$2"
  local head_index="$3"
  local -n kinds_state_ref="$kinds_name"
  local -n marked_state_ref="$marked_name"

  local index
  local total=0
  local on=0

  for ((index = head_index + 1; index < ${#kinds_state_ref[@]}; index++)); do
    if [[ "${kinds_state_ref[$index]}" == "g" ]]; then
      break
    fi
    ((total += 1))
    if [[ "${marked_state_ref[$index]:-0}" == "1" ]]; then
      ((on += 1))
    fi
  done

  if ((total == 0 || on == 0)); then
    printf -v "$4" '%s' empty
  elif ((on < total)); then
    printf -v "$4" '%s' partial
  else
    printf -v "$4" '%s' full
  fi
}

# Sets every item row owned by a group row to one state.
_ui_multiselect_group_set() {
  local marked_name="$1"
  local kinds_name="$2"
  local head_index="$3"
  local state="$4"
  local -n kinds_set_ref="$kinds_name"
  local -n marked_set_ref="$marked_name"

  local index

  for ((index = head_index + 1; index < ${#kinds_set_ref[@]}; index++)); do
    if [[ "${kinds_set_ref[$index]}" == "g" ]]; then
      break
    fi
    marked_set_ref[$index]="$state"
  done
}

# Stores one when every item row is marked, zero otherwise.
_ui_multiselect_all_state() {
  local kinds_name="$1"
  local marked_name="$2"
  local -n kinds_all_ref="$kinds_name"
  local -n marked_all_ref="$marked_name"

  local index
  local total=0
  local on=0

  for ((index = 0; index < ${#kinds_all_ref[@]}; index++)); do
    if [[ "${kinds_all_ref[$index]}" != "i" ]]; then
      continue
    fi
    ((total += 1))
    if [[ "${marked_all_ref[$index]:-0}" == "1" ]]; then
      ((on += 1))
    fi
  done

  if ((total > 0 && on == total)); then
    printf -v "$3" '%d' 1
  else
    printf -v "$3" '%d' 0
  fi
}

# Returns the number of terminal lines a redraw has to move the cursor up: the
# blank line, the count line, and the rendered height of every row.
_ui_multiselect_redraw_lines() {
  local kinds_name="$1"
  local -n kinds_lines_ref="$kinds_name"

  local index
  local line_count=2
  local seen_group="no"

  for ((index = 0; index < ${#kinds_lines_ref[@]}; index++)); do
    if [[ "${kinds_lines_ref[$index]}" == "g" ]]; then
      if [[ "$seen_group" == "yes" ]]; then
        ((line_count += 1))
      fi
      seen_group="yes"
    fi
    ((line_count += 1))
  done

  printf -v "$2" '%d' "$line_count"
}

# Draws the selected-items count line for a checkbox list.
_ui_draw_multiselect_count() {
  local -n kinds_ref="$1"
  local marked_name="$2"
  local -n marked_ref="$marked_name"
  local option_count="$3"
  local count=0
  local i

  for ((i = 1; i < option_count; i++)); do
    if [[ "${kinds_ref[$i]:-i}" == "i" && "${marked_ref[$i]:-0}" == "1" ]]; then
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
# Takes the canonical array names so redraws never pass a nameref alias.
_ui_read_multiselect_choice() {
  local cursor_index="$1"
  local kinds_name="$2"
  local marked_name="$3"
  shift 3
  local -n kinds_ref="$kinds_name"
  local -n marked_ref="$marked_name"

  local options=("$@")
  local option_count="${#options[@]}"
  local key=""
  local escape_sequence=""
  local i
  local redraw_lines=0
  local group_state
  local all_state=0

  _ui_multiselect_redraw_lines "$kinds_name" redraw_lines

  while true; do
    key=""
    if ! IFS= read -rsn1 key; then
      return 130
    fi

    case "$key" in
      " ")
        if ((cursor_index == 0)); then
          if [[ "${marked_ref[0]:-0}" == "1" ]]; then
            all_state=0
          else
            all_state=1
          fi
          for ((i = 1; i < option_count; i++)); do
            if [[ "${kinds_ref[$i]}" == "i" ]]; then
              marked_ref[$i]="$all_state"
            fi
          done
          marked_ref[0]="$all_state"
        else
          if [[ "${kinds_ref[$cursor_index]}" == "g" ]]; then
            _ui_multiselect_group_state "$kinds_name" "$marked_name" \
              "$cursor_index" group_state
            if [[ "$group_state" == "full" ]]; then
              _ui_multiselect_group_set "$marked_name" "$kinds_name" \
                "$cursor_index" 0
            else
              _ui_multiselect_group_set "$marked_name" "$kinds_name" \
                "$cursor_index" 1
            fi
          else
            marked_ref[$cursor_index]=$((1 - ${marked_ref[$cursor_index]:-0}))
          fi
          _ui_multiselect_all_state "$kinds_name" "$marked_name" all_state
          marked_ref[0]="$all_state"
        fi
        printf '\033[%dA' "$redraw_lines"
        _ui_draw_multiselect_count "$kinds_name" "$marked_name" "$option_count"
        _ui_draw_multiselect_options "$cursor_index" "$kinds_name" \
          "$marked_name" "${options[@]}"
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

          printf '\033[%dA' "$redraw_lines"
          _ui_draw_multiselect_count "$kinds_name" "$marked_name" "$option_count"
          _ui_draw_multiselect_options "$cursor_index" "$kinds_name" \
            "$marked_name" "${options[@]}"
        fi
        ;;
    esac
  done
}

# Runs a checkbox list from parallel row and kind arrays and stores the checked
# item rows in the caller-provided array. Row 0 is the select-everything row,
# kind "g" is a group row that owns the following item rows, kind "i" is a
# toggleable item. A group row other than the first is preceded by a blank line.
# The three array names must differ, otherwise the result would overwrite the
# input instead of being stored in the caller's array.
_ui_multiselect_run() {
  local result_name="$1"
  local prompt="$2"
  local rows_name="$3"
  local kinds_name="$4"

  if [[ "$result_name" == "$rows_name" || "$result_name" == "$kinds_name" ||
    "$rows_name" == "$kinds_name" ]]; then
    printf 'Checkbox list needs three different array names, got: %s\n' \
      "$result_name $rows_name $kinds_name" >&2
    return 1
  fi

  local -n rows_ref="$rows_name"
  local -n kinds_ref="$kinds_name"

  local -a option_rows=("All" "${rows_ref[@]}")
  local -a row_kinds=("a" "${kinds_ref[@]}")
  local -A marked=()
  local index
  local -a checked_items=()

  if ((${#option_rows[@]} <= 1)); then
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
  _ui_draw_multiselect_count row_kinds marked "${#option_rows[@]}"
  _ui_draw_multiselect_options 0 row_kinds marked "${option_rows[@]}"
  _ui_read_multiselect_choice 0 row_kinds marked "${option_rows[@]}" || return

  for index in "${!row_kinds[@]}"; do
    if [[ "${row_kinds[$index]}" != "i" ]]; then continue; fi
    if [[ "${marked[$index]:-0}" == "1" ]]; then
      checked_items+=("${option_rows[index]}")
    fi
  done

  local -n result_ref="$result_name"
  result_ref=("${checked_items[@]}")
}

# Renders a checkbox list and returns the names of the checked items.
# The result array name must not be rows or kinds, because that name is
# shadowed by the locals below while the result is stored.
ui_multiselect() {
  local result_name="$1"
  local prompt="$2"
  shift 2

  local -a item_rows=("$@")
  local -a item_kinds=()
  local index

  for ((index = 0; index < ${#item_rows[@]}; index++)); do
    item_kinds+=("i")
  done

  _ui_multiselect_run "$result_name" "$prompt" item_rows item_kinds
}

# Renders a checkbox list whose items are grouped under selectable group rows
# and returns the names of the checked items. Both arrays are passed by name
# and must be parallel: group rows carry the group label, item rows the item.
# The three array names must be distinct and must not match a local of the
# checkbox renderer, or the result would be stored in the wrong array.
ui_multiselect_grouped() {
  _ui_multiselect_run "$1" "$2" "$3" "$4"
}
