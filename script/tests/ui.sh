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
trap 'rm -f -- "$menu_output"' EXIT
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

printf 'UI interface validation passed.\n'
