#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../logic/load.sh
source "${script_root}/logic/load.sh"

detail=""
ui_detail detail "Description" one two
[[ "$detail" == $'Description\n  one, two' ]]

selection=""
menu_output="$(mktemp)"
stripped_output="$(mktemp)"
error_output="$(mktemp)"
trap 'rm -f -- "$menu_output" "$stripped_output" "$error_output"' EXIT
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

# Group rows render, are preceded by a blank line, and only item rows carry a
# selectable result.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" grouped_rows grouped_kinds \
  <<< $'\n' >"$menu_output"
[[ "${#grouped_selection[@]}" -eq 0 ]]
grep -Fq '[ ] Tools' "$menu_output"
grep -Fq '[ ] Media' "$menu_output"

# Every group row except the first is preceded by a blank line.
sed $'s/\r\\x1b\\[2K//g' "$menu_output" >"$stripped_output"
awk '
  { if (previous == "" && $0 ~ /\[.\] Media$/) { separated = 1 } previous = $0 }
  END { exit separated ? 0 : 1 }
' "$stripped_output"

# Space on a group row selects exactly the items that follow it.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" grouped_rows grouped_kinds \
  <<< "$down $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'one two three' ]]

# A group row shows partial state once one of its items is toggled on its own.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" grouped_rows grouped_kinds \
  <<< "$down$down $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'one' ]]
grep -Fq '[-] Tools' "$menu_output"

# All marks every item, All again clears every item.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" grouped_rows grouped_kinds \
  <<< " $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'one two three four five' ]]
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" grouped_rows grouped_kinds \
  <<< "  $'\n'" >"$menu_output"
[[ "${#grouped_selection[@]}" -eq 0 ]]

# Toggling a full group off leaves the other groups untouched.
grouped_selection=()
ui_multiselect_grouped grouped_selection "Prompt" grouped_rows grouped_kinds \
  <<< " $down $'\n'" >"$menu_output"
[[ "${grouped_selection[*]}" == 'four five' ]]

# A list without group rows behaves like a plain checkbox list.
plain_selection=()
ui_multiselect plain_selection "Prompt" one two three <<< "$down $'\n'" \
  >"$menu_output"
[[ "$plain_selection" == "one" ]]

# The result array name must not be shadowed by a local of the renderer.
shadow_rows=(one two three)
ui_multiselect shadow_rows "Prompt" one two three <<< $'\n' >"$menu_output"
[[ "${#shadow_rows[@]}" -eq 0 ]]
shadow_options=(one two three)
ui_multiselect shadow_options "Prompt" one two three <<< $'\n' >"$menu_output"
[[ "${#shadow_options[@]}" -eq 0 ]]

# Reusing one array name for more than one role is rejected, not silently
# allowed to overwrite the caller's input.
if ui_multiselect_grouped same "Prompt" same grouped_kinds <<< $'\n' \
  2>"$error_output" >"$menu_output"; then
  exit 1
fi
grep -Fq 'three different array names' "$error_output"

printf 'UI interface validation passed.\n'
