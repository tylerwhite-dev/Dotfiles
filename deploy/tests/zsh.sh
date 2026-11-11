#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

# All account checks and shell changes are test doubles.
id() {
  if [[ "$1" == -un ]]; then printf '%s\n' fixture; return; fi
  [[ "$1" == -u && "$2" == fixture && "${account_available:-yes}" == yes ]]
}
executor_require() {
  [[ "$1" == chsh && "${chsh_available:-yes}" == yes ]] && return 0
  error_report error.command_missing
  return 1
}
_zsh_default_shell_available() { [[ "${shell_available:-yes}" == yes ]]; }
error_report() { errors+=("$1"); }
executor_run_as_root() { commands+=("$*"); return "${chsh_status:-0}"; }
USER=fixture
unset SUDO_USER

for failure in account chsh shell; do
  (
    errors=() commands=() actual=0
    case "$failure" in
      account) account_available=no; expected=error.current_user_unknown ;;
      chsh) chsh_available=no; expected=error.command_missing ;;
      shell) shell_available=no; expected=error.zsh_missing ;;
    esac
    action_set_zsh_default fedora '' || actual=$?
    [[ "$actual" == 1 && "${errors[*]}" == "$expected" && "${#commands[@]}" == 0 ]]
  )
done

# Existing accounts succeed; a failing chsh preserves its failure status.
for chsh_status in 0 7; do
  errors=() commands=() actual=0
  action_set_zsh_default fedora '' || actual=$?
  [[ "$actual" == "$chsh_status" && "${commands[*]}" == 'chsh -s /bin/zsh fixture' ]]
done

# User discovery still works without USER; an invalid explicit user is rejected.
(
  unset USER
  chsh_status=0 errors=() commands=()
  action_set_zsh_default fedora ''
  [[ "${commands[*]}" == 'chsh -s /bin/zsh fixture' ]]
)
(
  SUDO_USER=missing
  errors=() commands=() actual=0
  action_set_zsh_default fedora '' || actual=$?
  [[ "$actual" == 1 && "${errors[*]}" == error.current_user_unknown && "${#commands[@]}" == 0 ]]
)

printf 'Zsh environment validation passed.\n'
