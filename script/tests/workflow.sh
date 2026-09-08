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

printf 'Workflow validation passed.\n'
