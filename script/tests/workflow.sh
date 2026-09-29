#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Prints a workflow assertion failure and terminates the test.
fail() {
  printf 'Workflow test failed: %s\n' "$1" >&2
  exit 1
}

# Returns success when an expected item exists in the provided array.
contains() {
  local expected="$1"
  shift
  local item

  for item in "$@"; do
    [[ "$item" == "$expected" ]] && return 0
  done
  return 1
}

# shellcheck source=../logic/load.sh
source "${script_root}/logic/load.sh"

catalog_validate
workflow_reset
workflow_select homebrew no
workflow_select homebrew_extended yes
workflow_select dotfiles yes

declare -a selected=()
workflow_selected selected fedora

contains dotfiles "${selected[@]}" || fail "dotfiles should be selected"
if contains homebrew_extended "${selected[@]}"; then
  fail "a procedure with an unselected requirement must be excluded"
fi

workflow_select homebrew yes
workflow_selected selected fedora
contains homebrew_extended "${selected[@]}" || \
  fail "a procedure with a selected requirement should be included"

workflow_selected selected macos
if contains homebrew_casks "${selected[@]}"; then
  fail "macOS casks must remain unselected until packages are chosen"
fi
workflow_select homebrew no
workflow_select_packages_all homebrew_casks macos
workflow_selected selected macos
if contains homebrew_casks "${selected[@]}"; then
  fail "selected macOS casks require the core Homebrew package set"
fi
if workflow_requirement_is_selected homebrew_casks; then
  fail "the cask question must be skipped when core Homebrew is not selected"
fi
workflow_select homebrew yes
workflow_requirement_is_selected homebrew_casks || \
  fail "the cask question must be available after core Homebrew is selected"
workflow_selected selected macos
contains homebrew_casks "${selected[@]}" || \
  fail "selected macOS casks should be included after core Homebrew"
workflow_selected selected fedora
if contains homebrew_casks "${selected[@]}"; then
  fail "macOS casks must not appear on Linux"
fi
casks=()
workflow_selected_packages casks homebrew_casks
[[ "${#casks[@]}" -eq 29 ]] || fail "YOLO must select every cask"

# The cask command is handed to the direct-input finish handler.
catalog_finish_handler finish_handler homebrew_casks
[[ "$finish_handler" == action_install_homebrew_casks ]] || \
  fail "cask installation must use the direct-input finish handler"
cask_command="$(
  executor_brew() { printf '%s\n' "$*"; }
  status_report() { :; }
  workflow_select_packages homebrew_casks firefox bitwarden
  action_install_homebrew_casks macos ''
)"
[[ "$cask_command" == 'install --cask firefox bitwarden' ]] || \
  fail "cask installation must use only selected packages"

printf 'Workflow validation passed.\n'
