#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../logic/load.sh
source "${script_root}/logic/load.sh"

detail=""
ui_detail detail "Description" one two
[[ "$detail" == $'Description\n  one, two' ]]

declare -A checkbox_texts=()
questionnaire_multiselect_texts checkbox_texts

selection=""
menu_output="$(mktemp)"
error_output="$(mktemp)"
trap 'rm -f -- "$menu_output" "$error_output"' EXIT
_ui_print_detail "$detail" >"$menu_output"
grep -Fxq '  Description' "$menu_output"
grep -Fxq '  one, two' "$menu_output"

ui_select selection "Prompt" "" 0 minimal one two three \
  <<< $'\n' >"$menu_output"
[[ "$selection" == "0" ]]
grep -Fq '    › one' "$menu_output"
grep -Fq '      two' "$menu_output"
grep -Fq '      three' "$menu_output"

saved_success_color="$ui_color_success"
saved_heading_color="$ui_color_heading"
saved_reset_color="$ui_color_reset"
ui_color_success='<success>'
ui_color_reset='</reset>'
success_output="$(ui_success_line 'Elapsed')"
[[ "$success_output" == '<success>Elapsed</reset>' ]]
ui_color_heading='<heading>'
heading_output="$(ui_heading_line 'Elapsed')"
[[ "$heading_output" == '<heading>Elapsed</reset>' ]]
ui_color_success="$saved_success_color"
ui_color_heading="$saved_heading_color"
ui_color_reset="$saved_reset_color"

ui_select selection "Prompt" "" 0 default one two three \
  <<< $'\n' >"$menu_output"
grep -Fq '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' "$menu_output"

# Narrow menus keep each option on one row and return the original index.
COLUMNS=16 ui_select selection "Prompt" "" 0 minimal \
  'a long option label' second <<< $'\033[B\n' >"$menu_output"
[[ "$selection" == 1 ]]
grep -Fq 'a long o…' "$menu_output"
if grep -Fq 'a long option label' "$menu_output"; then exit 1; fi

# Timeline rows leave room for progress and duration in a narrow terminal.
active_line="$(COLUMNS=30 ui_color_comment= ui_color_heading= ui_color_hint= ui_color_reset= \
  ui_timeline_active 1 8 'A very long procedure label' 45 '◉' yes)"
finished_line="$(COLUMNS=30 ui_color_success= ui_color_hint= ui_color_reset= \
  ui_timeline_finished 0 'A very long procedure label' 135)"
[[ "$active_line" == *'00:45' && "$finished_line" == *'2m 15s' ]]
[[ "$active_line" == $'\r\033[2K'* ]]
active_line="${active_line#$'\r\033[2K'}"
[[ "${#active_line}" -lt 30 && "${#finished_line}" -lt 30 ]]

saved_success_color="$ui_color_success"
saved_hint_color="$ui_color_hint"
saved_reset_color="$ui_color_reset"
ui_color_success='<success>'
ui_color_hint='<hint>'
ui_color_reset='</reset>'
packages_output="$(ui_summary_item_packages 'Extended set' 5 '5 selected')"
[[ "$packages_output" == '<success>●</reset>  Extended set  <success>5 selected</reset>' ]]
empty_packages_output="$(ui_summary_item_packages 'Extended set' 0 'no packages selected')"
[[ "$empty_packages_output" == '<hint>○</reset>  Extended set  no packages selected' ]]
ui_color_success="$saved_success_color"
ui_color_hint="$saved_hint_color"
ui_color_reset="$saved_reset_color"

down=$'\033[B'
grouped_rows=('Tools' one two three 'Media' four five)
grouped_kinds=(g i i i g i i)

# Group rows render, only item rows carry a selectable result, and the grouped
# view has no global All row.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" checkbox_texts grouped_rows grouped_kinds \
  <<< $'\n' >"$menu_output"
[[ "${#grouped_selection[@]}" -eq 0 ]]
grep -Fq '[ ] Tools' "$menu_output"
grep -Fq '[ ] Media' "$menu_output"
if grep -Fq '[ ] All' "$menu_output"; then exit 1; fi

# The menu is displayed in an alternate screen and restored on exit.
grep -Fq $'\033[?1049h' "$menu_output"
grep -Fq $'\033[?1049l' "$menu_output"

# Space on a group row selects exactly the items that follow it.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" checkbox_texts grouped_rows grouped_kinds \
  <<< " $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'one two three' ]]

# A group row shows partial state once one of its items is toggled on its own.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" checkbox_texts grouped_rows grouped_kinds \
  <<< "$down $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'one' ]]
grep -Fq '[-] Tools' "$menu_output"

# Each category can be selected and cleared independently.
four_down="$down$down$down$down"
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" checkbox_texts grouped_rows grouped_kinds \
  <<< " $four_down $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'one two three four five' ]]
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" checkbox_texts grouped_rows grouped_kinds \
  <<< "  $'\n'" >"$menu_output"
[[ "${#grouped_selection[@]}" -eq 0 ]]

# Toggling a full group off leaves the other groups untouched.
up=$'\033[A'
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" checkbox_texts grouped_rows grouped_kinds \
  <<< " $four_down $up$up$up$up $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'four five' ]]

# A grouped call without category rows still starts with its first item.
bare_rows=(one two)
bare_kinds=(i i)
bare_selection=()
ui_multiselect_grouped bare_selection "Prompt" checkbox_texts bare_rows bare_kinds \
  <<< " $'\n'" >"$menu_output"
[[ "${bare_selection[*]}" == one ]]
if grep -Fq '[ ] All' "$menu_output"; then exit 1; fi

# A list without group rows behaves like a plain checkbox list.
plain_selection=()
ui_multiselect plain_selection "Prompt" checkbox_texts one two three <<< "$down $'\n'" \
  >"$menu_output"
[[ "$plain_selection" == "one" ]]
ui_multiselect plain_selection "Prompt" checkbox_texts one two three <<< " $'\n'" \
  >"$menu_output"
[[ "${plain_selection[*]}" == 'one two three' ]]

# The result array name must not be shadowed by a local of the renderer.
shadow_rows=(one two three)
ui_multiselect shadow_rows "Prompt" checkbox_texts one two three <<< $'\n' >"$menu_output"
[[ "${#shadow_rows[@]}" -eq 0 ]]
shadow_options=(one two three)
ui_multiselect shadow_options "Prompt" checkbox_texts one two three <<< $'\n' >"$menu_output"
[[ "${#shadow_options[@]}" -eq 0 ]]

# Reusing one array name for more than one role is rejected, not silently
# allowed to overwrite the caller's input.
if ui_multiselect_grouped same "Prompt" checkbox_texts same grouped_kinds <<< $'\n' \
  2>"$error_output" >"$menu_output"; then
  exit 1
fi
grep -Fq 'different array names' "$error_output"

# The layout counts real and repeated headings against the 24-line limit.
many_kinds=(g)
for ((i=0; i<25; i++)); do many_kinds+=(i); done
declare -A cells=()
declare -a columns=() positions=()
column_count=0
_ui_ms_layout many_kinds 24 cells columns positions column_count
[[ "$column_count" == 2 ]]
[[ "${cells[0,23]}" == 23 ]]
[[ "${cells[1,0]}" == -1 ]]
[[ "${cells[1,1]}" == 24 ]]
[[ "${columns[24]}" == 1 ]]
many_kinds+=(g i)
_ui_ms_layout many_kinds 24 cells columns positions column_count
[[ "$column_count" == 3 ]]
[[ "${columns[26]}" == 2 ]]

# Each category starts its own column even when the previous one has space.
separate_kinds=(g i i g i)
_ui_ms_layout separate_kinds 24 cells columns positions column_count
[[ "$column_count" == 2 ]]
[[ "${columns[0]}" == 0 && "${columns[3]}" == 1 ]]
[[ "${cells[1,0]}" == 3 ]]

real_rows=()
real_kinds=()
catalog_package_rows real_rows real_kinds homebrew_extended macos brew
[[ "${#real_rows[@]}" -gt 24 ]]
real_layout=("${real_kinds[@]}")
_ui_ms_layout real_layout 20 cells columns positions column_count
[[ "$column_count" -gt 1 ]]

# A narrow viewport shifts when the focus reaches the next hidden column.
many_rows=()
for ((i=0; i<25; i++)); do many_rows+=("item-$i"); done
keys=''
for ((i=0; i<24; i++)); do keys+=$'\033[B'; done
keys+=$' \n'
many_selection=()
LINES=28 COLUMNS=18 ui_multiselect many_selection "Prompt" checkbox_texts "${many_rows[@]}" \
  <<< "$keys" >"$menu_output"
[[ "${many_selection[*]}" == item-23 ]]
grep -Fq 'cols 2-2/2' "$menu_output"
grep -Fq '→' "$menu_output"
grep -Fq '←' "$menu_output"
# Scrolling redraws the frame without clearing the whole screen again.
[[ "$(grep -oF $'\033[2J' "$menu_output" | wc -l)" -eq 1 ]]

# The middle of a hidden-column window shows both directions at once.
three_rows=(First one Second two Third three)
three_kinds=(g i g i g i)
three_selection=()
LINES=28 COLUMNS=18 ui_multiselect_grouped three_selection "Prompt" checkbox_texts \
  three_rows three_kinds <<< $'\033[C\n' >"$menu_output"
grep -q '←.*→' "$menu_output"

# Horizontal navigation targets real items, including across the viewport edge.
many_selection=()
LINES=28 COLUMNS=18 ui_multiselect many_selection "Prompt" checkbox_texts "${many_rows[@]}" \
  <<< $'\033[C \n' >"$menu_output"
[[ "${many_selection[*]}" == item-23 ]]

# Names are truncated only when printed, and exit restores the prior trap.
[[ "$(_ui_ms_fit abcdefgh 5)" == 'abcd…' ]]
before_trap="$(trap -p EXIT)"
ui_multiselect selection "Prompt" checkbox_texts one <<< $'\n' >"$menu_output"
[[ "$(trap -p EXIT)" == "$before_trap" ]]

# An unusably short terminal waits for a key, then EOF returns 130.
if LINES=5 COLUMNS=80 ui_multiselect selection "Prompt" checkbox_texts one \
  </dev/null >"$menu_output"; then
  exit 1
else
  [[ "$?" == 130 ]]
fi
grep -Fq 'Increase terminal size' "$menu_output"

# An unexpected exit restores the screen and preserves a caller's EXIT trap.
cleanup_marker="$(mktemp)"
rm -f -- "$cleanup_marker"
UI_CLEANUP_MARKER="$cleanup_marker" bash -c '
  source "$1"
  trap '\''printf done >"$UI_CLEANUP_MARKER"'\'' EXIT
  _ui_ms_screen_open
  exit 9
' bash "${script_root}/ui/ui.sh" >"$menu_output" 2>"$error_output" && exit 1
[[ "$(cat "$cleanup_marker")" == done ]]
grep -Fq $'\033[?1049l' "$menu_output"
rm -f -- "$cleanup_marker"

if bash -c 'source "$1"; _ui_ms_screen_open; kill -INT "$$"' \
  bash "${script_root}/ui/ui.sh" >"$menu_output" 2>"$error_output"; then
  exit 1
else
  [[ "$?" == 130 ]]
fi
grep -Fq $'\033[?1049l' "$menu_output"

# Caller names must never resolve to a widget's local state.
for output_name in cursor index rows result_ref prompt choice_value; do
  unset "$output_name"
  declare -a "$output_name"
  declare -n output_ref="$output_name"
  output_ref=(original)
  ui_multiselect "$output_name" "Prompt" checkbox_texts one <<< $' \n' >"$menu_output"
  [[ "${output_ref[*]}" == one ]]
  unset -n output_ref
  unset "$output_name"
  ui_select "$output_name" "Prompt" "" 0 minimal one two <<< $'\033OB\n' >"$menu_output"
  [[ "${!output_name}" == 1 ]]
done
ui_detail description 'Text' one
[[ "$description" == $'Text\n  one' ]]
ui_timeline_frame frame_index 0
[[ "$frame_index" == "${ui_timeline_frames[0]}" ]]

# Direct UI loading works with caller-owned text, without logic/config modules.
(
  trap - EXIT
  source "${script_root}/ui/ui.sh"
  unset -f message_format catalog_packages workflow_select
  declare -A own_texts=(
    [all_label]='Everything' [status_format]='%d:%d/%d checked=%d'
    [navigation_hint]='Custom hint' [resize_notice]='Custom resize'
  )
  chosen=()
  ui_multiselect chosen Prompt own_texts one <<< $' \n' >"$menu_output"
  [[ "${chosen[*]}" == one ]]
  grep -Fq '[x] Everything' "$menu_output"
  grep -Fq 'checked=1' "$menu_output"
  grep -Fq 'Custom hint' "$menu_output"
)

# Invalid input never enters the screen or replaces the previous result.
expect_invalid() {
  local expected="$1" actual=0
  shift
  saved=(original)
  "$@" >"$menu_output" 2>"$error_output" || actual=$?
  [[ "$actual" == "$expected" && "${saved[*]}" == original && ! -s "$menu_output" ]]
}
__ui_reserved=(original)
expect_invalid 2 ui_multiselect __ui_reserved Prompt checkbox_texts one
expect_invalid 2 ui_select __ui_reserved Prompt '' 0 minimal one
expect_invalid 2 ui_multiselect 'bad[name]' Prompt checkbox_texts one
expect_invalid 2 ui_multiselect saved Prompt checkbox_texts
expect_invalid 1 ui_multiselect_grouped saved Prompt checkbox_texts saved bare_kinds
bad_rows=(Heading one); bad_kinds=(g)
expect_invalid 2 ui_multiselect_grouped saved Prompt checkbox_texts bad_rows bad_kinds
bad_kinds=(g g)
expect_invalid 2 ui_multiselect_grouped saved Prompt checkbox_texts bad_rows bad_kinds
bad_kinds=(i x)
expect_invalid 2 ui_multiselect_grouped saved Prompt checkbox_texts bad_rows bad_kinds
bad_rows=(Heading); bad_kinds=(g)
expect_invalid 2 ui_multiselect_grouped saved Prompt checkbox_texts bad_rows bad_kinds
bad_rows=([1]=one); bad_kinds=([1]=i)
expect_invalid 2 ui_multiselect_grouped saved Prompt checkbox_texts bad_rows bad_kinds
empty_texts=()
expect_invalid 2 ui_multiselect saved Prompt empty_texts one
declare -A incomplete_texts=([all_label]=All)
expect_invalid 2 ui_multiselect saved Prompt incomplete_texts one
output_target=(original)
declare -n output_alias=output_target text_alias=checkbox_texts
expect_invalid 2 ui_multiselect output_alias Prompt checkbox_texts one
expect_invalid 2 ui_multiselect saved Prompt text_alias one
unset -n output_alias text_alias
readonly locked_output=original
expect_invalid 2 ui_select locked_output Prompt '' 0 minimal one

saved=(original)
status=0
ui_multiselect saved Prompt checkbox_texts one </dev/null >"$menu_output" || status=$?
[[ "$status" == 130 && "${saved[*]}" == original ]]
grep -Fq $'\033[?1049l' "$menu_output"

# Shared key decoding covers both terminal arrow encodings and interruption.
for prefix in '[' O; do
  for pair in A:up B:down C:right D:left; do
    _ui_read_key event <<< $'\033'"$prefix${pair%%:*}"
    [[ "$event" == "${pair#*:}" ]]
  done
done
_ui_read_key event <<< $'\n'; [[ "$event" == enter ]]
_ui_read_key event <<< ' '; [[ "$event" == space ]]
_ui_read_key event <<< x; [[ "$event" == unknown ]]
_ui_read_key event <<< $'\033[Z'; [[ "$event" == unknown ]]
status=0
_ui_read_key event </dev/null || status=$?
[[ "$status" == 130 ]]
_ui_truncate text abc 0; [[ -z "$text" ]]
_ui_truncate text abc -1; [[ -z "$text" ]]
_ui_truncate text abc 1; [[ "$text" == '…' ]]
_ui_truncate text abc 3; [[ "$text" == abc ]]

# Equal-distance neighbors retain the first logical row.
neighbor_columns=(0 1 1); neighbor_positions=(1 0 2)
_ui_ms_neighbor neighbor 0 right neighbor_columns neighbor_positions 2
[[ "$neighbor" == 1 ]]
_ui_ms_neighbor neighbor 0 left neighbor_columns neighbor_positions 2
[[ "$neighbor" == 0 ]]
_ui_ms_neighbor neighbor 1 left neighbor_columns neighbor_positions 2
[[ "$neighbor" == 0 ]]
roundtrip_selection=()
LINES=28 COLUMNS=18 ui_multiselect_grouped roundtrip_selection Prompt checkbox_texts \
  three_rows three_kinds <<< $'\033[C\033[D \n' >"$menu_output"
[[ "${roundtrip_selection[*]}" == one ]]

# Reopening must leave the original traps and active screen intact.
(
  trap ':' EXIT
  original_exit="$(trap -p EXIT)"
  _ui_ms_screen_open
  active_exit="$(trap -p EXIT)"
  status=0
  _ui_ms_screen_open || status=$?
  [[ "$status" == 2 && "$(trap -p EXIT)" == "$active_exit" ]]
  _ui_ms_screen_close
  [[ "$(trap -p EXIT)" == "$original_exit" ]]
) >"$menu_output"
[[ "$(grep -oF $'\033[?1049h' "$menu_output" | wc -l)" -eq 1 ]]

status=0
bash -c 'source "$1"; _ui_ms_screen_open; kill -TERM "$$"' \
  bash "${script_root}/ui/ui.sh" >"$menu_output" 2>"$error_output" || status=$?
[[ "$status" == 143 ]]
grep -Fq $'\033[?1049l' "$menu_output"

printf 'UI interface validation passed.\n'
