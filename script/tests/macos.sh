#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

# All system-changing commands are replaced; these checks can run off macOS.
events=()
status_report() { events+=("$1"); }
error_report() { events+=("$1"); }
executor_require() { return 0; }
executor_run() {
  events+=("$*")
  if [[ "$1" == xcode-select ]]; then return "$request_status"; fi
  return 0
}

# Readiness preserves the selected Xcode/CLT and rejects an unusable compiler.
xcode-select() { [[ "$*" == -p ]]; return "$selection_status"; }
xcrun() { [[ "$*" == 'clang --version' ]]; return "$compiler_status"; }
for selection_status in 0 1; do
  for compiler_status in 0 1; do
    actual=0
    executor_macos_developer_tools_ready || actual=$?
    if ((selection_status == 0 && compiler_status == 0)); then
      [[ "$actual" == 0 ]]
    else
      [[ "$actual" != 0 ]]
    fi
  done
done

# A working toolchain must skip the system installer and read no input.
selection_status=0 compiler_status=0 request_status=0 events=()
action_install_macos_command_line_tools macos '' </dev/null
[[ "${events[*]}" == status.macos_clt_ready ]]

# Installer errors must retain their status and never wait for confirmation.
selection_status=1 request_status=7 events=() actual=0
action_install_macos_command_line_tools macos '' </dev/null || actual=$?
[[ "$actual" == 7 && "${events[*]}" == 'xcode-select --install' ]]

# Enter is only a trigger to verify; it cannot make incomplete tools succeed.
request_status=0 events=() actual=0
action_install_macos_command_line_tools macos '' <<< '' || actual=$?
[[ "$actual" == 1 && "${events[-1]}" == error.macos_clt_missing ]]

# EOF is not success and the message must not claim no changes were applied.
events=() actual=0
action_install_macos_command_line_tools macos '' </dev/null || actual=$?
[[ "$actual" == 130 && "${events[-1]}" == error.macos_clt_wait_interrupted ]]

# Only actual toolchain readiness after the dialog can complete installation.
checks=0
executor_macos_developer_tools_ready() { ((checks+=1)); ((checks > 1)); }
events=()
action_install_macos_command_line_tools macos '' <<< ''
[[ "$checks" == 2 && "${events[-1]}" == status.macos_clt_ready ]]

# The CLT finish handler must run with direct input; Linux remains unchanged.
catalog_finish_handler finish_handler macos_command_line_tools
[[ "$finish_handler" == action_install_macos_command_line_tools ]]
workflow_reset
for procedure in macos_command_line_tools macos_finder macos_spaces homebrew; do
  workflow_select "$procedure" yes
done
workflow_selected selected macos
[[ "${selected[*]}" == 'macos_command_line_tools macos_finder macos_spaces homebrew' ]]
workflow_selected selected fedora
[[ "${selected[*]}" == homebrew ]]

# No preference operation may touch the status bar, shortcuts or other keys.
declare -A preferences=(
  ['com.apple.finder/ShowStatusBar']=existing-status-bar
  ['com.apple.symbolichotkeys/AppleSymbolicHotKeys']=existing-shortcuts
  ['com.apple.dock/autohide']=existing-dock-setting
)
executor_run() {
  if [[ "$1" == defaults ]]; then
    [[ "$2" == write ]]
    preferences["$3/$4"]="$6"
  else
    events+=("$*")
  fi
}
pgrep() { return 1; }
action_configure_macos_finder macos ''
action_configure_macos_spaces macos ''
[[ "${preferences[com.apple.finder/ShowStatusBar]}" == existing-status-bar ]]
[[ "${preferences[com.apple.symbolichotkeys/AppleSymbolicHotKeys]}" == existing-shortcuts ]]
[[ "${preferences[com.apple.dock/autohide]}" == existing-dock-setting ]]
[[ "${preferences[com.apple.finder/NewWindowTarget]}" == PfHm ]]
[[ "${preferences[com.apple.dock/mru-spaces]}" == false ]]

# Restarts must be scoped to the current user and the requested app only.
pgrep() { [[ "$*" == "-u $(id -u) -x Finder" ]]; }
events=()
executor_restart_macos_app Finder
[[ "${events[*]}" == "killall -u $(id -un) Finder" ]]
actual=0
executor_restart_macos_app unrelated || actual=$?
[[ "$actual" == 2 ]]

# A clean macOS Homebrew path must stop before download if tools are missing.
OSTYPE=darwin
executor_macos_developer_tools_ready() { return 1; }
events=() actual=0
action_install_homebrew_binary || actual=$?
[[ "$actual" == 1 && "${events[*]}" == error.macos_clt_missing ]]

# Missing sudo credentials must be prepared before any installer download.
executor_macos_developer_tools_ready() { return 0; }
sudo() { return "$sudo_status"; }
executor_prepare_privilege() { events+=(prepare-privilege); return "$privilege_status"; }
executor_temp_file() { return 6; }
sudo_status=1 privilege_status=4 events=() actual=0
action_install_homebrew_binary || actual=$?
[[ "$actual" == 4 && "${events[*]}" == 'status.homebrew_admin_prompt prepare-privilege' ]]
privilege_status=0 events=() actual=0
action_install_homebrew_binary || actual=$?
[[ "$actual" == 6 && "${events[*]}" == 'status.homebrew_admin_prompt prepare-privilege' ]]
sudo_status=0 events=() actual=0
action_install_homebrew_binary || actual=$?
[[ "$actual" == 6 && "${#events[@]}" == 0 ]]

printf 'macOS procedure validation passed.\n'
