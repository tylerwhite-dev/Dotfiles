#!/usr/bin/env bash

# The checkbox menu owns the alternate screen only while it is active.
_ui_ms_screen_open() {
  _ui_ms_old_exit="$(trap -p EXIT)"
  _ui_ms_old_int="$(trap -p INT)"
  _ui_ms_old_term="$(trap -p TERM)"
  _ui_ms_screen_active=1
  printf '\033[?1049h\033[?25l'
  trap '_ui_ms_exit' EXIT
  trap '_ui_ms_abort 130' INT
  trap '_ui_ms_abort 143' TERM
}

_ui_ms_screen_close() {
  if [[ "${_ui_ms_screen_active:-0}" == 1 ]]; then
    printf '\033[?25h\033[?1049l'
    _ui_ms_screen_active=0
  fi
  if [[ -n "${_ui_ms_old_exit:-}" ]]; then eval "$_ui_ms_old_exit"; else trap - EXIT; fi
  if [[ -n "${_ui_ms_old_int:-}" ]]; then eval "$_ui_ms_old_int"; else trap - INT; fi
  if [[ -n "${_ui_ms_old_term:-}" ]]; then eval "$_ui_ms_old_term"; else trap - TERM; fi
}

_ui_ms_abort() {
  local status="$1"
  _ui_ms_screen_close
  exit "$status"
}

# An unexpected shell exit must also run the EXIT handler that was present
# before this menu opened (for example, a caller's temporary-file cleanup).
_ui_ms_exit() {
  local status="$?"
  local previous="${_ui_ms_old_exit:-}"
  _ui_ms_screen_close
  if [[ -n "$previous" ]]; then
    eval "set -- ${previous#trap -- }"
    eval "$1"
  fi
  exit "$status"
}

# Read live geometry first. LINES/COLUMNS remain useful for redirected UI tests.
_ui_ms_size() {
  local -n height_ref="$1"
  local -n width_ref="$2"
  local size_height="${LINES:-24}"
  local size_width="${COLUMNS:-80}"
  local live_height live_width
  if [[ -t 1 ]] && read -r live_height live_width < <(stty size </dev/tty 2>/dev/null); then
    if [[ "$live_height" =~ ^[1-9][0-9]*$ && "$live_width" =~ ^[1-9][0-9]*$ ]]; then
      size_height="$live_height"
      size_width="$live_width"
    fi
  fi
  [[ "$size_height" =~ ^[1-9][0-9]*$ ]] || size_height=24
  [[ "$size_width" =~ ^[1-9][0-9]*$ ]] || size_width=80
  height_ref="$size_height"
  width_ref="$size_width"
}

_ui_ms_group_state() {
  local -n kinds_ref="$1"
  local -n marked_ref="$2"
  local head="$3" index total=0 on=0
  for ((index=head+1; index<${#kinds_ref[@]}; index++)); do
    [[ "${kinds_ref[index]}" == g ]] && break
    ((total+=1))
    [[ "${marked_ref[$index]:-0}" == 1 ]] && ((on+=1))
  done
  if ((on == 0)); then printf -v "$4" '%s' empty
  elif ((on == total)); then printf -v "$4" '%s' full
  else printf -v "$4" '%s' partial
  fi
}

_ui_ms_group_set() {
  local -n kinds_ref="$1"
  local -n marked_ref="$2"
  local head="$3" state="$4" index
  for ((index=head+1; index<${#kinds_ref[@]}; index++)); do
    [[ "${kinds_ref[index]}" == g ]] && break
    marked_ref[$index]="$state"
  done
}

_ui_ms_all_state() {
  local -n kinds_ref="$1"
  local -n marked_ref="$2"
  local index
  [[ "${kinds_ref[0]}" == a ]] || return 0
  for ((index=1; index<${#kinds_ref[@]}; index++)); do
    if [[ "${kinds_ref[index]}" == i && "${marked_ref[$index]:-0}" != 1 ]]; then
      marked_ref[0]=0
      return
    fi
  done
  marked_ref[0]=1
}

_ui_ms_toggle() {
  local -n kinds_ref="$1"
  local -n marked_ref="$2"
  local index="$3" i state
  if [[ "${kinds_ref[index]}" == a ]]; then
    state=$((1-${marked_ref[0]:-0}))
    for ((i=1; i<${#kinds_ref[@]}; i++)); do
      [[ "${kinds_ref[i]}" == i ]] && marked_ref[$i]="$state"
    done
    marked_ref[0]="$state"
  elif [[ "${kinds_ref[index]}" == g ]]; then
    _ui_ms_group_state "$1" "$2" "$index" state
    if [[ "$state" == full ]]; then state=0; else state=1; fi
    _ui_ms_group_set "$1" "$2" "$index" "$state"
    _ui_ms_all_state "$1" "$2"
  else
    marked_ref[$index]=$((1-${marked_ref[$index]:-0}))
    _ui_ms_all_state "$1" "$2"
  fi
}

# Layout stores logical indices in physical cells. Negative values are
# decorative copies of the active group title and never receive focus.
_ui_ms_layout() {
  local -n kinds_ref="$1"
  local limit="$2"
  local -n cells_ref="$3"
  local -n cols_ref="$4"
  local -n positions_ref="$5"
  local index start=0 column=0 row=0 group=-1
  cells_ref=(); cols_ref=(); positions_ref=()
  if [[ "${kinds_ref[0]}" == a ]]; then
    cols_ref[0]=0
    positions_ref[0]=-1
    start=1
  fi
  for ((index=start; index<${#kinds_ref[@]}; index++)); do
    if [[ "${kinds_ref[index]}" == g ]]; then
      # A category always begins a fresh column, even if the prior one has room.
      if ((row > 0)); then ((column+=1)); row=0; fi
      group="$index"
    elif ((row >= limit)); then
      ((column+=1)); row=0
      if ((group >= 0)); then
        cells_ref["$column,$row"]=$((-group-1))
        ((row+=1))
      fi
    fi
    cells_ref["$column,$row"]="$index"
    cols_ref[index]="$column"
    positions_ref[index]="$row"
    ((row+=1))
  done
  printf -v "$6" '%d' "$((column+1))"
}

_ui_ms_fit() {
  local value="$1" limit="$2"
  if ((${#value} > limit)); then
    value="${value:0:limit-1}…"
  fi
  printf '%-*s' "$limit" "$value"
}

# Draw one cell with a fixed visible width, including focus and checkbox marks.
_ui_ms_cell() {
  local -n rows_ref="$1"
  local -n kinds_ref="$2"
  local -n marked_ref="$3"
  local value="$4" cursor="$5" width="$6"
  local index label mark color text prefix
  if ((value < 0)); then
    index=$((-value-1))
    label="↳ ${rows_ref[index]}"
    prefix='          '
    color="$ui_color_group"
  else
    index="$value"
    label="${rows_ref[index]}"
    if [[ "${kinds_ref[index]}" == g ]]; then
      _ui_ms_group_state "$2" "$3" "$index" text
      case "$text" in
        full) mark='[x]' ;;
        partial) mark='[-]' ;;
        *) mark='[ ]' ;;
      esac
      color="$ui_color_group"
    else
      if [[ "${marked_ref[$index]:-0}" == 1 ]]; then mark='[x]'; else mark='[ ]'; fi
      color="$ui_color_reset"
    fi
    if ((index == cursor)); then prefix="    › $mark "; color="$ui_color_selected"
    else prefix="      $mark "; fi
  fi
  printf '%s%s%s' "$prefix" "$color" "$(_ui_ms_fit "$label" "$((width-10))")"
  printf '%s' "$ui_color_reset"
}

_ui_ms_draw() {
  local -n rows_ref="$1"
  local -n kinds_ref="$2"
  local -n marked_ref="$3"
  local -n cells_ref="$4"
  local prompt="$5" cursor="$6" height="$7" width="$8" first="$9"
  local visible="${10}" cell_width="${11}" column_count="${12}"
  local row col cell selected=0 heading count_line left_indicator=' ' right_indicator=' '
  for ((row=0; row<${#kinds_ref[@]}; row++)); do
    [[ "${kinds_ref[row]}" == i && "${marked_ref[$row]:-0}" == 1 ]] && ((selected+=1))
  done
  printf '\033[H\033[2J%s%s%s\n' "$ui_color_question" "$(_ui_ms_fit "$prompt" "$((width-1))")" "$ui_color_reset"
  printf -v count_line 'cols %d-%d/%d  ·  %d selected' \
    "$((first+1))" "$((first+visible))" "$column_count" "$selected"
  ((first > 0)) && left_indicator='←'
  ((first+visible < column_count)) && right_indicator='→'
  printf '%s%s%s %s %s%s%s\n' \
    "$ui_color_selected" "$left_indicator" "$ui_color_hint" \
    "$(_ui_ms_fit "$count_line" "$((width-5))")" \
    "$ui_color_selected" "$right_indicator" "$ui_color_reset"
  if [[ "${kinds_ref[0]}" == a ]]; then
    printf '\033[2K'
    _ui_ms_cell "$1" "$2" "$3" 0 "$cursor" "$cell_width"
    printf '\n\n'
  else
    printf '\n'
  fi
  for ((row=0; row<height; row++)); do
    printf '\033[2K'
    for ((col=0; col<visible; col++)); do
      if ((col > 0)); then printf '  '; fi
      cell="${cells_ref[$((first+col)),$row]:-}"
      if [[ -n "$cell" ]]; then
        _ui_ms_cell "$1" "$2" "$3" "$cell" "$cursor" "$cell_width"
      else
        printf '%*s' "$cell_width" ''
      fi
    done
    printf '\n'
  done
  heading='↑↓ move  ←→ column  Space toggle  Enter confirm'
  printf '%s%s%s' "$ui_color_hint" "$(_ui_ms_fit "$heading" "$((width-1))")" "$ui_color_reset"
}

_ui_ms_key() {
  local -n key_ref="$1"
  local sequence
  key_ref=''
  IFS= read -rsn1 key_ref || return 130
  if [[ "$key_ref" == $'\033' ]]; then
    sequence=''
    if IFS= read -rsn2 -t 0.2 sequence; then
      case "$sequence" in
        '[A'|'OA') key_ref=up ;;
        '[B'|'OB') key_ref=down ;;
        '[C'|'OC') key_ref=right ;;
        '[D'|'OD') key_ref=left ;;
        *) key_ref=unknown ;;
      esac
    fi
  fi
}

_ui_ms_run() {
  local result_name="$1" prompt="$2" rows_name="$3" kinds_name="$4" with_all="$5"
  if [[ "$result_name" == "$rows_name" || "$result_name" == "$kinds_name" || "$rows_name" == "$kinds_name" ]]; then
    printf 'Checkbox list needs three different array names, got: %s\n' \
      "$result_name $rows_name $kinds_name" >&2
    return 1
  fi
  local -n input_rows_ref="$rows_name"
  local -n input_kinds_ref="$kinds_name"
  local -a _ms_rows=() _ms_kinds=()
  if [[ "$with_all" == yes ]]; then
    _ms_rows=(All "${input_rows_ref[@]}")
    _ms_kinds=(a "${input_kinds_ref[@]}")
  else
    _ms_rows=("${input_rows_ref[@]}")
    _ms_kinds=("${input_kinds_ref[@]}")
  fi
  local -a _ms_cols=() _ms_positions=() checked=()
  local -A _ms_marked=() _ms_cells=()
  local cursor=0 first=0 height width limit cell_width visible column_count
  local max_label=0 index key target_col target_row candidate best_distance distance
  local status=0
  ((${#input_rows_ref[@]} > 0)) || return 2
  _ui_ms_screen_open
  while true; do
    _ui_ms_size height width
    if [[ "$with_all" == yes ]]; then
      limit=$((height-5))
      ((limit > 23)) && limit=23
    else
      limit=$((height-4))
      ((limit > 24)) && limit=24
    fi
    if ((limit < 2 || width < 16)); then
      printf '\033[H\033[2JIncrease terminal size, then press a key.'
      _ui_ms_key key || { status=$?; break; }
      continue
    fi
    _ui_ms_layout _ms_kinds "$limit" _ms_cells _ms_cols _ms_positions column_count
    max_label=0
    for ((index=0; index<${#_ms_rows[@]}; index++)); do
      candidate=${#_ms_rows[index]}
      [[ "${_ms_kinds[index]}" == g ]] && ((candidate+=2))
      ((candidate > max_label)) && max_label="$candidate"
    done
    cell_width=$((max_label+10))
    ((cell_width > width-1)) && cell_width=$((width-1))
    visible=$(((width-1+2)/(cell_width+2)))
    ((visible < 1)) && visible=1
    ((visible > column_count)) && visible="$column_count"
    if ((cursor < ${#_ms_cols[@]})); then
      ((first > _ms_cols[cursor])) && first=${_ms_cols[cursor]}
      ((_ms_cols[cursor] >= first+visible)) && first=$((_ms_cols[cursor]-visible+1))
    fi
    ((first > column_count-visible)) && first=$((column_count-visible))
    _ui_ms_draw _ms_rows _ms_kinds _ms_marked _ms_cells "$prompt" "$cursor" \
      "$limit" "$width" "$first" "$visible" "$cell_width" "$column_count"
    _ui_ms_key key || { status=$?; break; }
    case "$key" in
      '') break ;;
      ' ') _ui_ms_toggle _ms_kinds _ms_marked "$cursor" ;;
      up) cursor=$(((cursor-1+${#_ms_rows[@]})%${#_ms_rows[@]})) ;;
      down) cursor=$(((cursor+1)%${#_ms_rows[@]})) ;;
      left|right)
        target_col=${_ms_cols[cursor]}
        if [[ "$key" == left ]]; then ((target_col-=1)); else ((target_col+=1)); fi
        if ((target_col >= 0 && target_col < column_count)); then
          target_row=${_ms_positions[cursor]}
          candidate=-1 best_distance=9999
          for ((index=0; index<${#_ms_rows[@]}; index++)); do
            ((${_ms_cols[index]} == target_col)) || continue
            distance=$((target_row-${_ms_positions[index]}))
            ((distance < 0)) && distance=$((-distance))
            if ((distance < best_distance)); then
              candidate="$index" best_distance="$distance"
            fi
          done
          ((candidate >= 0)) && cursor="$candidate"
        fi
        ;;
    esac
  done
  _ui_ms_screen_close
  ((status == 0)) || return "$status"
  for ((index=0; index<${#_ms_rows[@]}; index++)); do
    if [[ "${_ms_kinds[index]}" == i && "${_ms_marked[$index]:-0}" == 1 ]]; then
      checked+=("${_ms_rows[index]}")
    fi
  done
  local -n result_ref="$result_name"
  result_ref=("${checked[@]}")
}

ui_multiselect() {
  local result_name="$1" prompt="$2" index
  shift 2
  local -a item_rows=("$@") item_kinds=()
  for ((index=0; index<${#item_rows[@]}; index++)); do item_kinds+=(i); done
  _ui_ms_run "$result_name" "$prompt" item_rows item_kinds yes
}

ui_multiselect_grouped() {
  _ui_ms_run "$1" "$2" "$3" "$4" no
}
