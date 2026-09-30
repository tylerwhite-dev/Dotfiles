#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${script_root}/logic/load.sh"
ui_is_interactive || { printf 'This check requires a real TTY.\n' >&2; exit 2; }

# Only fixture handlers execute. No privilege or installation operations occur.
test_action() { printf 'Fixture output\n'; return "$action_status"; }
test_finish() {
  [[ "$BASHPID" == "$parent_pid" && -t 0 && -t 1 ]]
  [[ "$1" == platform && "$2" == repository ]]
  finish_called=yes
  printf '\nFinish handler in parent shell with direct TTY input.\n'
  return "$finish_status"
}
for action_status in 0 7; do
  for finish_status in 0 9; do
    parent_pid="$BASHPID" finish_called=no actual=0
    process_run test_action 1 1 Fixture no platform repository test_finish || actual=$?
    expected="$action_status"
    if ((action_status == 0)); then expected="$finish_status"; fi
    [[ "$actual" == "$expected" ]]
    if ((action_status == 0)); then [[ "$finish_called" == yes ]]; else [[ "$finish_called" == no ]]; fi
  done
done
stderr_marker="$(mktemp)"
trap 'rm -f -- "$stderr_marker"' EXIT
{
  action_status=0 finish_status=0 parent_pid="$BASHPID" finish_called=no
  process_run test_action 1 1 Fixture no platform repository test_finish
  printf 'Parent stderr preserved.\n' >&2
} 2>"$stderr_marker"
grep -Fxq 'Parent stderr preserved.' "$stderr_marker"
printf 'Animated process TTY validation passed.\n'
