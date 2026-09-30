#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${script_root}/logic/load.sh"
ui_is_interactive || { printf 'This check requires a real TTY.\n' >&2; exit 2; }

# Scripted keys exercise the actual TTY geometry and screen session.
read -r original_height original_width < <(stty size </dev/tty)
frames="$(mktemp)"; geometry="$(mktemp)"
trap 'stty rows "$original_height" cols "$original_width" </dev/tty; rm -f -- "$frames" "$geometry"' EXIT
declare -A checkbox_texts=()
questionnaire_multiselect_texts checkbox_texts
eval "$(declare -f _ui_ms_draw | sed '1s/_ui_ms_draw/_test_draw/')"
eval "$(declare -f _ui_read_key | sed '1s/_ui_read_key/_test_key/')"

test_resize() {
  local measured_height measured_width
  stty rows "$1" cols "$2" </dev/tty
  read -r measured_height measured_width < <(stty size </dev/tty)
  if [[ "$measured_height" != "$1" || "$measured_width" != "$2" ]]; then
    printf 'This TTY does not support stty resize; use a Linux/macOS TTY.\n' >&2
    return 2
  fi
}

_ui_ms_draw() {
  local test_frame
  test_frame="$(_test_draw "$@")"
  printf '%s\n' "$test_frame" >>"$frames"
  printf '%s,%s\n' "$7" "$8" >>"$geometry"
  printf '%s' "$test_frame"
}
_ui_read_key() {
  _test_key "$1" || return
  ((key_count+=1))
  if [[ "$resize_on_key" == yes && "$key_count" == 1 ]]; then
    test_resize 11 45 || return
  fi
  return 0
}

test_resize 28 18
key_count=0 resize_on_key=no
choice=''
ui_select choice Prompt '' 0 minimal one two <<< $'\033[B\n'
[[ "$choice" == 1 ]]

rows=(First one Second two Third three); kinds=(g i g i g i); selected=()
ui_multiselect_grouped selected Prompt checkbox_texts rows kinds <<< $'\033[C \n'
[[ "${selected[*]}" == two ]]
grep -q '←.*→' "$frames"
grep -Fq 'cols 2-2/3' "$frames"
ui_multiselect_grouped selected Prompt checkbox_texts rows kinds <<< $'\033[C\033[D \n'
[[ "${selected[*]}" == one ]]

many=()
for ((index=0; index<25; index++)); do many+=("item-$index"); done
ui_multiselect selected Prompt checkbox_texts "${many[@]}" <<< $'\033[C \n'
[[ "${selected[*]}" == item-23 ]]
grep -Fq 'cols 2-2/2' "$frames"

: >"$geometry"
test_resize 8 18
key_count=0 resize_on_key=yes
ui_multiselect_grouped selected Prompt checkbox_texts rows kinds <<< $'\033[C \n'
[[ "${selected[*]}" == two ]]
grep -Fxq '4,18' "$geometry"
grep -Fxq '7,45' "$geometry"

resize_on_key=no
selected=(original); status=0
ui_multiselect selected Prompt checkbox_texts one </dev/null || status=$?
[[ "$status" == 130 && "${selected[*]}" == original ]]
test_resize 5 80
status=0
ui_multiselect selected Prompt checkbox_texts one </dev/null || status=$?
[[ "$status" == 130 && "${selected[*]}" == original ]]

stty rows "$original_height" cols "$original_width" </dev/tty
for signal in INT TERM; do
  status=0
  bash -c 'source "$1"; _ui_ms_screen_open; kill -"$2" "$$"' \
    bash "${script_root}/ui/ui.sh" "$signal" || status=$?
  if [[ "$signal" == INT ]]; then [[ "$status" == 130 ]]; else [[ "$status" == 143 ]]; fi
done
printf '\nUI TTY geometry and interruption validation passed.\n'
