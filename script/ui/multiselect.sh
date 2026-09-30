#!/usr/bin/env bash

# The checkbox menu owns the alternate screen only while it is active.
_ui_ms_screen_open() {
  [[ "${__ui_ms_screen_active:-0}" == 0 ]] || return 2
  __ui_ms_old_exit="$(trap -p EXIT)"
  __ui_ms_old_int="$(trap -p INT)"
  __ui_ms_old_term="$(trap -p TERM)"
  __ui_ms_screen_active=1
  printf '\033[?1049h\033[?25l\033[H\033[2J'
  trap '_ui_ms_exit' EXIT
  trap '_ui_ms_abort 130' INT
  trap '_ui_ms_abort 143' TERM
}

_ui_ms_screen_close() {
  if [[ "${__ui_ms_screen_active:-0}" == 1 ]]; then
    printf '\033[?25h\033[?1049l'
    __ui_ms_screen_active=0
  fi
  if [[ -n "${__ui_ms_old_exit:-}" ]]; then eval "$__ui_ms_old_exit"; else trap - EXIT; fi
  if [[ -n "${__ui_ms_old_int:-}" ]]; then eval "$__ui_ms_old_int"; else trap - INT; fi
  if [[ -n "${__ui_ms_old_term:-}" ]]; then eval "$__ui_ms_old_term"; else trap - TERM; fi
}

_ui_ms_abort() {
  local __ui_abort_status="$1"
  _ui_ms_screen_close
  exit "$__ui_abort_status"
}

# An unexpected shell exit must also run the EXIT handler that was present
# before this menu opened (for example, a caller's temporary-file cleanup).
_ui_ms_exit() {
  local __ui_exit_status="$?"
  local __ui_exit_previous="${__ui_ms_old_exit:-}"
  _ui_ms_screen_close
  if [[ -n "$__ui_exit_previous" ]]; then
    eval "set -- ${__ui_exit_previous#trap -- }"
    eval "$1"
  fi
  exit "$__ui_exit_status"
}

# Read live geometry first. LINES/COLUMNS remain useful for redirected UI tests.
_ui_ms_size() {
  local -n __ui_size_height_ref="$1"
  local -n __ui_size_width_ref="$2"
  local __ui_size_size_height="${LINES:-24}"
  local __ui_size_size_width="${COLUMNS:-80}"
  local __ui_size_live_height __ui_size_live_width
  if [[ -t 1 ]] && read -r __ui_size_live_height __ui_size_live_width < <(stty size </dev/tty 2>/dev/null); then
    if [[ "$__ui_size_live_height" =~ ^[1-9][0-9]*$ && "$__ui_size_live_width" =~ ^[1-9][0-9]*$ ]]; then
      __ui_size_size_height="$__ui_size_live_height"
      __ui_size_size_width="$__ui_size_live_width"
    fi
  fi
  [[ "$__ui_size_size_height" =~ ^[1-9][0-9]*$ ]] || __ui_size_size_height=24
  [[ "$__ui_size_size_width" =~ ^[1-9][0-9]*$ ]] || __ui_size_size_width=80
  __ui_size_height_ref="$__ui_size_size_height"
  __ui_size_width_ref="$__ui_size_size_width"
}

_ui_ms_group_state() {
  local -n __ui_gs_kinds_ref="$1"
  local -n __ui_gs_marked_ref="$2"
  local __ui_gs_head="$3" __ui_gs_index __ui_gs_total=0 __ui_gs_on=0
  for ((__ui_gs_index=__ui_gs_head+1; __ui_gs_index<${#__ui_gs_kinds_ref[@]}; __ui_gs_index++)); do
    [[ "${__ui_gs_kinds_ref[__ui_gs_index]}" == g ]] && break
    ((__ui_gs_total+=1))
    [[ "${__ui_gs_marked_ref[$__ui_gs_index]:-0}" == 1 ]] && ((__ui_gs_on+=1))
  done
  if ((__ui_gs_on == 0)); then printf -v "$4" '%s' empty
  elif ((__ui_gs_on == __ui_gs_total)); then printf -v "$4" '%s' full
  else printf -v "$4" '%s' partial
  fi
}

_ui_ms_group_set() {
  local -n __ui_set_kinds_ref="$1"
  local -n __ui_set_marked_ref="$2"
  local __ui_set_head="$3" __ui_set_state="$4" __ui_set_index
  for ((__ui_set_index=__ui_set_head+1; __ui_set_index<${#__ui_set_kinds_ref[@]}; __ui_set_index++)); do
    [[ "${__ui_set_kinds_ref[__ui_set_index]}" == g ]] && break
    __ui_set_marked_ref[$__ui_set_index]="$__ui_set_state"
  done
}

_ui_ms_all_state() {
  local -n __ui_all_kinds_ref="$1"
  local -n __ui_all_marked_ref="$2"
  local __ui_all_index
  [[ "${__ui_all_kinds_ref[0]}" == a ]] || return 0
  for ((__ui_all_index=1; __ui_all_index<${#__ui_all_kinds_ref[@]}; __ui_all_index++)); do
    if [[ "${__ui_all_kinds_ref[__ui_all_index]}" == i && "${__ui_all_marked_ref[$__ui_all_index]:-0}" != 1 ]]; then
      __ui_all_marked_ref[0]=0
      return
    fi
  done
  __ui_all_marked_ref[0]=1
}

_ui_ms_toggle() {
  local -n __ui_toggle_kinds_ref="$1"
  local -n __ui_toggle_marked_ref="$2"
  local __ui_toggle_index="$3" __ui_toggle_i __ui_toggle_state
  if [[ "${__ui_toggle_kinds_ref[__ui_toggle_index]}" == a ]]; then
    __ui_toggle_state=$((1-${__ui_toggle_marked_ref[0]:-0}))
    for ((__ui_toggle_i=1; __ui_toggle_i<${#__ui_toggle_kinds_ref[@]}; __ui_toggle_i++)); do
      [[ "${__ui_toggle_kinds_ref[__ui_toggle_i]}" == i ]] && __ui_toggle_marked_ref[$__ui_toggle_i]="$__ui_toggle_state"
    done
    __ui_toggle_marked_ref[0]="$__ui_toggle_state"
  elif [[ "${__ui_toggle_kinds_ref[__ui_toggle_index]}" == g ]]; then
    _ui_ms_group_state "$1" "$2" "$__ui_toggle_index" __ui_toggle_state
    if [[ "$__ui_toggle_state" == full ]]; then __ui_toggle_state=0; else __ui_toggle_state=1; fi
    _ui_ms_group_set "$1" "$2" "$__ui_toggle_index" "$__ui_toggle_state"
    _ui_ms_all_state "$1" "$2"
  else
    __ui_toggle_marked_ref[$__ui_toggle_index]=$((1-${__ui_toggle_marked_ref[$__ui_toggle_index]:-0}))
    _ui_ms_all_state "$1" "$2"
  fi
}

# Layout stores logical indices in physical cells. Negative values are
# decorative copies of the active group title and never receive focus.
_ui_ms_layout() {
  local -n __ui_layout_kinds_ref="$1"
  local __ui_layout_limit="$2"
  local -n __ui_layout_cells_ref="$3"
  local -n __ui_layout_cols_ref="$4"
  local -n __ui_layout_positions_ref="$5"
  local __ui_layout_index __ui_layout_start=0 __ui_layout_column=0 __ui_layout_row=0 __ui_layout_group=-1
  __ui_layout_cells_ref=(); __ui_layout_cols_ref=(); __ui_layout_positions_ref=()
  if [[ "${__ui_layout_kinds_ref[0]}" == a ]]; then
    __ui_layout_cols_ref[0]=0
    __ui_layout_positions_ref[0]=-1
    __ui_layout_start=1
  fi
  for ((__ui_layout_index=__ui_layout_start; __ui_layout_index<${#__ui_layout_kinds_ref[@]}; __ui_layout_index++)); do
    if [[ "${__ui_layout_kinds_ref[__ui_layout_index]}" == g ]]; then
      # A category always begins a fresh column, even if the prior one has room.
      if ((__ui_layout_row > 0)); then ((__ui_layout_column+=1)); __ui_layout_row=0; fi
      __ui_layout_group="$__ui_layout_index"
    elif ((__ui_layout_row >= __ui_layout_limit)); then
      ((__ui_layout_column+=1)); __ui_layout_row=0
      if ((__ui_layout_group >= 0)); then
        __ui_layout_cells_ref["$__ui_layout_column,$__ui_layout_row"]=$((-__ui_layout_group-1))
        ((__ui_layout_row+=1))
      fi
    fi
    __ui_layout_cells_ref["$__ui_layout_column,$__ui_layout_row"]="$__ui_layout_index"
    __ui_layout_cols_ref[__ui_layout_index]="$__ui_layout_column"
    __ui_layout_positions_ref[__ui_layout_index]="$__ui_layout_row"
    ((__ui_layout_row+=1))
  done
  printf -v "$6" '%d' "$((__ui_layout_column+1))"
}

_ui_ms_fit() {
  local __ui_fit_value __ui_fit_limit="$2"
  _ui_truncate __ui_fit_value "$1" "$__ui_fit_limit"
  ((__ui_fit_limit > 0)) || return 0
  printf '%-*s' "$__ui_fit_limit" "$__ui_fit_value"
}

# Draw one cell with a fixed visible width, including focus and checkbox marks.
_ui_ms_cell() {
  local -n __ui_cell_rows_ref="$1"
  local -n __ui_cell_kinds_ref="$2"
  local -n __ui_cell_marked_ref="$3"
  local __ui_cell_value="$4" __ui_cell_cursor="$5" __ui_cell_width="$6"
  local __ui_cell_index __ui_cell_label __ui_cell_mark __ui_cell_color __ui_cell_text __ui_cell_prefix
  if ((__ui_cell_value < 0)); then
    __ui_cell_index=$((-__ui_cell_value-1))
    __ui_cell_label="↳ ${__ui_cell_rows_ref[__ui_cell_index]}"
    __ui_cell_prefix='          '
    __ui_cell_color="$ui_color_group"
  else
    __ui_cell_index="$__ui_cell_value"
    __ui_cell_label="${__ui_cell_rows_ref[__ui_cell_index]}"
    if [[ "${__ui_cell_kinds_ref[__ui_cell_index]}" == g ]]; then
      _ui_ms_group_state "$2" "$3" "$__ui_cell_index" __ui_cell_text
      case "$__ui_cell_text" in
        full) __ui_cell_mark='[x]' ;;
        partial) __ui_cell_mark='[-]' ;;
        *) __ui_cell_mark='[ ]' ;;
      esac
      __ui_cell_color="$ui_color_group"
    else
      if [[ "${__ui_cell_marked_ref[$__ui_cell_index]:-0}" == 1 ]]; then __ui_cell_mark='[x]'; else __ui_cell_mark='[ ]'; fi
      __ui_cell_color="$ui_color_reset"
    fi
    if ((__ui_cell_index == __ui_cell_cursor)); then __ui_cell_prefix="    › $__ui_cell_mark "; __ui_cell_color="$ui_color_selected"
    else __ui_cell_prefix="      $__ui_cell_mark "; fi
  fi
  printf '%s%s%s' "$__ui_cell_prefix" "$__ui_cell_color" "$(_ui_ms_fit "$__ui_cell_label" "$((__ui_cell_width-10))")"
  printf '%s' "$ui_color_reset"
}

_ui_ms_draw() {
  local -n __ui_grid_rows_ref="$1"
  local -n __ui_grid_kinds_ref="$2"
  local -n __ui_grid_marked_ref="$3"
  local -n __ui_grid_cells_ref="$4"
  local __ui_grid_prompt="$5" __ui_grid_cursor="$6" __ui_grid_height="$7" __ui_grid_width="$8" __ui_grid_first="$9"
  local __ui_grid_visible="${10}" __ui_grid_cell_width="${11}" __ui_grid_column_count="${12}"
  local -n __ui_grid_texts_ref="${13}"
  local __ui_grid_row __ui_grid_col __ui_grid_cell __ui_grid_selected=0 __ui_grid_heading __ui_grid_count_line \
    __ui_grid_left_indicator=' ' __ui_grid_right_indicator=' '
  for ((__ui_grid_row=0; __ui_grid_row<${#__ui_grid_kinds_ref[@]}; __ui_grid_row++)); do
    [[ "${__ui_grid_kinds_ref[__ui_grid_row]}" == i && "${__ui_grid_marked_ref[$__ui_grid_row]:-0}" == 1 ]] && ((__ui_grid_selected+=1))
  done
  printf '\033[2K%s%s%s\n' "$ui_color_question" "$(_ui_ms_fit "$__ui_grid_prompt" "$((__ui_grid_width-1))")" "$ui_color_reset"
  printf -v __ui_grid_count_line "${__ui_grid_texts_ref[status_format]}" \
    "$((__ui_grid_first+1))" "$((__ui_grid_first+__ui_grid_visible))" "$__ui_grid_column_count" "$__ui_grid_selected"
  ((__ui_grid_first > 0)) && __ui_grid_left_indicator='←'
  ((__ui_grid_first+__ui_grid_visible < __ui_grid_column_count)) && __ui_grid_right_indicator='→'
  printf '\033[2K%s%s%s %s %s%s%s\n' \
    "$ui_color_selected" "$__ui_grid_left_indicator" "$ui_color_hint" \
    "$(_ui_ms_fit "$__ui_grid_count_line" "$((__ui_grid_width-5))")" \
    "$ui_color_selected" "$__ui_grid_right_indicator" "$ui_color_reset"
  if [[ "${__ui_grid_kinds_ref[0]}" == a ]]; then
    printf '\033[2K'
    _ui_ms_cell "$1" "$2" "$3" 0 "$__ui_grid_cursor" "$__ui_grid_cell_width"
    printf '\n\033[2K\n'
  else
    printf '\033[2K\n'
  fi
  for ((__ui_grid_row=0; __ui_grid_row<__ui_grid_height; __ui_grid_row++)); do
    printf '\033[2K'
    for ((__ui_grid_col=0; __ui_grid_col<__ui_grid_visible; __ui_grid_col++)); do
      if ((__ui_grid_col > 0)); then printf '  '; fi
      __ui_grid_cell="${__ui_grid_cells_ref[$((__ui_grid_first+__ui_grid_col)),$__ui_grid_row]:-}"
      if [[ -n "$__ui_grid_cell" ]]; then
        _ui_ms_cell "$1" "$2" "$3" "$__ui_grid_cell" "$__ui_grid_cursor" "$__ui_grid_cell_width"
      else
        printf '%*s' "$__ui_grid_cell_width" ''
      fi
    done
    printf '\n'
  done
  __ui_grid_heading="${__ui_grid_texts_ref[navigation_hint]}"
  printf '\033[2K%s%s%s' "$ui_color_hint" "$(_ui_ms_fit "$__ui_grid_heading" "$((__ui_grid_width-1))")" "$ui_color_reset"
}

# Checks role aliasing before any nameref or terminal state is created.
_ui_ms_distinct() {
  local -a __ui_distinct_names=("$@")
  local __ui_distinct_left __ui_distinct_right
  for ((__ui_distinct_left=0; __ui_distinct_left<${#__ui_distinct_names[@]}; __ui_distinct_left++)); do
    for ((__ui_distinct_right=__ui_distinct_left+1; __ui_distinct_right<${#__ui_distinct_names[@]}; __ui_distinct_right++)); do
      if [[ "${__ui_distinct_names[__ui_distinct_left]}" == "${__ui_distinct_names[__ui_distinct_right]}" ]]; then
        printf 'Checkbox list needs different array names, got: %s\n' "$*" >&2
        return 1
      fi
    done
  done
}

# All validation runs before opening the screen. A heading must own an item.
_ui_ms_validate() {
  _ui_array_type "$1" A || return
  _ui_array_type "$2" a || return
  _ui_array_type "$3" a || return
  local -n __ui_validate_texts_ref="$1" __ui_validate_rows_ref="$2" __ui_validate_kinds_ref="$3"
  local __ui_validate_index __ui_validate_name
  for __ui_validate_name in all_label status_format navigation_hint resize_notice; do
    [[ -v "__ui_validate_texts_ref[$__ui_validate_name]" ]] || return 2
  done
  ((${#__ui_validate_rows_ref[@]} > 0 && ${#__ui_validate_rows_ref[@]} == ${#__ui_validate_kinds_ref[@]})) || return 2
  for ((__ui_validate_index=0; __ui_validate_index<${#__ui_validate_rows_ref[@]}; __ui_validate_index++)); do
    [[ -v "__ui_validate_rows_ref[$__ui_validate_index]" ]] || return 2
    case "${__ui_validate_kinds_ref[__ui_validate_index]:-}" in
      i) ;;
      g) [[ "${__ui_validate_kinds_ref[__ui_validate_index+1]:-}" == i ]] || return 2 ;;
      *) return 2 ;;
    esac
  done
}

# Determines column width and visible count without modifying widget state.
_ui_ms_measure() {
  local -n __ui_measure_rows_ref="$1" __ui_measure_kinds_ref="$2"
  local __ui_measure_width="$3" __ui_measure_column_count="$4" __ui_measure_index __ui_measure_candidate \
    __ui_measure_max_label=0 __ui_measure_cell_width __ui_measure_visible
  for ((__ui_measure_index=0; __ui_measure_index<${#__ui_measure_rows_ref[@]}; __ui_measure_index++)); do
    __ui_measure_candidate=${#__ui_measure_rows_ref[__ui_measure_index]}
    [[ "${__ui_measure_kinds_ref[__ui_measure_index]}" == g ]] && ((__ui_measure_candidate+=2))
    ((__ui_measure_candidate > __ui_measure_max_label)) && __ui_measure_max_label="$__ui_measure_candidate"
  done
  __ui_measure_cell_width=$((__ui_measure_max_label+10))
  ((__ui_measure_cell_width > __ui_measure_width-1)) && __ui_measure_cell_width=$((__ui_measure_width-1))
  __ui_measure_visible=$(((__ui_measure_width+1)/(__ui_measure_cell_width+2)))
  ((__ui_measure_visible < 1)) && __ui_measure_visible=1
  ((__ui_measure_visible > __ui_measure_column_count)) && __ui_measure_visible="$__ui_measure_column_count"
  printf -v "$5" '%d' "$__ui_measure_cell_width"
  printf -v "$6" '%d' "$__ui_measure_visible"
}

# Keeps the nearest real row in the next column; ties retain logical order.
_ui_ms_neighbor() {
  local __ui_neighbor_cursor="$2" __ui_neighbor_direction="$3"
  local -n __ui_neighbor_cols_ref="$4" __ui_neighbor_positions_ref="$5"
  local __ui_neighbor_column_count="$6" __ui_neighbor_target_col="${__ui_neighbor_cols_ref[__ui_neighbor_cursor]}"
  local __ui_neighbor_target_row="${__ui_neighbor_positions_ref[__ui_neighbor_cursor]}" __ui_neighbor_index \
    __ui_neighbor_distance __ui_neighbor_best_distance=-1 __ui_neighbor_candidate="$__ui_neighbor_cursor"
  if [[ "$__ui_neighbor_direction" == left ]]; then
    __ui_neighbor_target_col=$((__ui_neighbor_target_col-1))
  else
    __ui_neighbor_target_col=$((__ui_neighbor_target_col+1))
  fi
  if ((__ui_neighbor_target_col >= 0 && __ui_neighbor_target_col < __ui_neighbor_column_count)); then
    for ((__ui_neighbor_index=0; __ui_neighbor_index<${#__ui_neighbor_cols_ref[@]}; __ui_neighbor_index++)); do
      ((${__ui_neighbor_cols_ref[__ui_neighbor_index]} == __ui_neighbor_target_col)) || continue
      __ui_neighbor_distance=$((__ui_neighbor_target_row-${__ui_neighbor_positions_ref[__ui_neighbor_index]}))
      ((__ui_neighbor_distance < 0)) && __ui_neighbor_distance=$((-__ui_neighbor_distance))
      if ((__ui_neighbor_best_distance < 0 || __ui_neighbor_distance < __ui_neighbor_best_distance)); then
        __ui_neighbor_candidate="$__ui_neighbor_index" __ui_neighbor_best_distance="$__ui_neighbor_distance"
      fi
    done
  fi
  printf -v "$1" '%d' "$__ui_neighbor_candidate"
}

# Returns original item values only, never group or decorative headings.
_ui_ms_selected() {
  local -n __ui_collect_result_ref="$1" __ui_collect_rows_ref="$2" __ui_collect_kinds_ref="$3" __ui_collect_marked_ref="$4"
  local -a __ui_collect_checked=()
  local __ui_collect_index
  for ((__ui_collect_index=0; __ui_collect_index<${#__ui_collect_rows_ref[@]}; __ui_collect_index++)); do
    if [[ "${__ui_collect_kinds_ref[__ui_collect_index]}" == i && "${__ui_collect_marked_ref[$__ui_collect_index]:-0}" == 1 ]]; then
      __ui_collect_checked+=("${__ui_collect_rows_ref[__ui_collect_index]}")
    fi
  done
  __ui_collect_result_ref=("${__ui_collect_checked[@]}")
}

# Owns one screen session; geometry and navigation helpers remain internal.
_ui_ms_run() {
  local __ui_run_result_name="$1" __ui_run_prompt="$2" __ui_run_texts_name="$3" __ui_run_rows_name="$4" \
    __ui_run_kinds_name="$5" __ui_run_with_all="$6"
  _ui_ms_validate "$__ui_run_texts_name" "$__ui_run_rows_name" "$__ui_run_kinds_name" || return
  local -n __ui_run_input_rows_ref="$__ui_run_rows_name" __ui_run_input_kinds_ref="$__ui_run_kinds_name" \
    __ui_run_texts_ref="$__ui_run_texts_name"
  local -a __ui_run_rows=() __ui_run_kinds=() __ui_run_cols=() __ui_run_positions=()
  if [[ "$__ui_run_with_all" == yes ]]; then
    __ui_run_rows=("${__ui_run_texts_ref[all_label]}" "${__ui_run_input_rows_ref[@]}")
    __ui_run_kinds=(a "${__ui_run_input_kinds_ref[@]}")
  else
    __ui_run_rows=("${__ui_run_input_rows_ref[@]}")
    __ui_run_kinds=("${__ui_run_input_kinds_ref[@]}")
  fi
  local -A __ui_run_marked=() __ui_run_cells=()
  local __ui_run_cursor=0 __ui_run_first=0 __ui_run_height __ui_run_width __ui_run_limit __ui_run_cell_width \
    __ui_run_visible __ui_run_column_count __ui_run_key __ui_run_status=0 __ui_run_frame
  _ui_ms_screen_open || return
  while true; do
    _ui_ms_size __ui_run_height __ui_run_width
    if [[ "$__ui_run_with_all" == yes ]]; then
      __ui_run_limit=$((__ui_run_height-5)); ((__ui_run_limit > 23)) && __ui_run_limit=23
    else
      __ui_run_limit=$((__ui_run_height-4)); ((__ui_run_limit > 24)) && __ui_run_limit=24
    fi
    if ((__ui_run_limit < 2 || __ui_run_width < 16)); then
      printf '\033[H\033[2J%s' "${__ui_run_texts_ref[resize_notice]}"
      _ui_read_key __ui_run_key || { __ui_run_status=$?; break; }
      continue
    fi
    _ui_ms_layout __ui_run_kinds "$__ui_run_limit" __ui_run_cells __ui_run_cols __ui_run_positions __ui_run_column_count
    _ui_ms_measure __ui_run_rows __ui_run_kinds "$__ui_run_width" "$__ui_run_column_count" __ui_run_cell_width __ui_run_visible
    ((__ui_run_first > __ui_run_cols[__ui_run_cursor])) && __ui_run_first=${__ui_run_cols[__ui_run_cursor]}
    ((__ui_run_cols[__ui_run_cursor] >= __ui_run_first+__ui_run_visible)) && __ui_run_first=$((__ui_run_cols[__ui_run_cursor]-__ui_run_visible+1))
    ((__ui_run_first > __ui_run_column_count-__ui_run_visible)) && __ui_run_first=$((__ui_run_column_count-__ui_run_visible))
    __ui_run_frame="$(_ui_ms_draw __ui_run_rows __ui_run_kinds __ui_run_marked __ui_run_cells "$__ui_run_prompt" "$__ui_run_cursor" \
      "$__ui_run_limit" "$__ui_run_width" "$__ui_run_first" "$__ui_run_visible" "$__ui_run_cell_width" "$__ui_run_column_count" "$__ui_run_texts_name")"
    printf '\033[H%s\033[J' "$__ui_run_frame"
    _ui_read_key __ui_run_key || { __ui_run_status=$?; break; }
    case "$__ui_run_key" in
      enter) break ;;
      space) _ui_ms_toggle __ui_run_kinds __ui_run_marked "$__ui_run_cursor" ;;
      up) __ui_run_cursor=$(((__ui_run_cursor-1+${#__ui_run_rows[@]})%${#__ui_run_rows[@]})) ;;
      down) __ui_run_cursor=$(((__ui_run_cursor+1)%${#__ui_run_rows[@]})) ;;
      left|right) _ui_ms_neighbor __ui_run_cursor "$__ui_run_cursor" "$__ui_run_key" __ui_run_cols __ui_run_positions "$__ui_run_column_count" ;;
    esac
  done
  _ui_ms_screen_close
  ((__ui_run_status == 0)) || return "$__ui_run_status"
  _ui_ms_selected "$__ui_run_result_name" __ui_run_rows __ui_run_kinds __ui_run_marked
}

# Explicit text array, then item values. Outputs change only on confirmation.
ui_multiselect() {
  (($# >= 3)) || return 2
  _ui_ms_distinct "$1" "$3" || return
  _ui_output_name "$1" || return
  _ui_valid_name "$3" || return
  local __ui_flat_result="$1" __ui_flat_prompt="$2" __ui_flat_texts="$3" __ui_flat_index
  shift 3
  local -a __ui_flat_rows=("$@") __ui_flat_kinds=()
  for ((__ui_flat_index=0; __ui_flat_index<${#__ui_flat_rows[@]}; __ui_flat_index++)); do
    __ui_flat_kinds+=(i)
  done
  _ui_ms_run "$__ui_flat_result" "$__ui_flat_prompt" "$__ui_flat_texts" __ui_flat_rows __ui_flat_kinds yes
}

# g/i rows are presentation data; only original item values are returned.
ui_multiselect_grouped() {
  (($# == 5)) || return 2
  _ui_ms_distinct "$1" "$3" "$4" "$5" || return
  _ui_output_name "$1" || return
  _ui_valid_name "$3" || return
  _ui_valid_name "$4" || return
  _ui_valid_name "$5" || return
  _ui_ms_run "$1" "$2" "$3" "$4" "$5" no
}
