#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

ui_timeline_active() { :; }
ui_timeline_finished() { final_status="$1"; }
ui_is_interactive() { return 1; }
status_report() { :; }
executor_prepare_privilege() { privilege_called=yes; return "${privilege_status:-0}"; }
sudo() { return 1; }

test_action() { action_called=yes; return "$action_status"; }
test_finish() {
  [[ "$BASHPID" == "$parent_pid" && "$1" == platform && "$2" == repository ]]
  finish_called=yes
  return "$finish_status"
}

for action_status in 0 7; do
  for finish_status in 0 9; do
    parent_pid="$BASHPID" action_called=no finish_called=no final_status=-1 actual=0
    process_run test_action 1 1 Label no platform repository test_finish >/dev/null || actual=$?
    expected="$action_status"
    if ((action_status == 0)); then expected="$finish_status"; fi
    [[ "$actual" == "$expected" && "$final_status" == "$expected" && "$action_called" == yes ]]
    if ((action_status == 0)); then [[ "$finish_called" == yes ]]; else [[ "$finish_called" == no ]]; fi
  done
done

action_status=0 actual=0 finish_called=no
process_run test_action 1 1 Label no platform repository '' >/dev/null || actual=$?
[[ "$actual" == 0 && "$finish_called" == no && "$final_status" == 0 ]]

privilege_status=4 action_called=no finish_called=no actual=0
process_run test_action 1 1 Label yes platform repository test_finish >/dev/null || actual=$?
[[ "$actual" == 1 && "$final_status" == 1 && "$privilege_called" == yes ]]
[[ "$action_called" == no && "$finish_called" == no ]]
printf 'Process completion validation passed.\n'
