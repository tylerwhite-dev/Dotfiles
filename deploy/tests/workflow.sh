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
workflow_select homebrew_casks yes
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
# Selecting Homebrew alone must not implicitly select optional packages, so
# neither optional package set may reach the runner in that state.
workflow_reset
workflow_select homebrew yes
workflow_selected selected macos
contains homebrew "${selected[@]}" || fail "core Homebrew should be selected"
if contains homebrew_extended "${selected[@]}"; then
  fail "optional brew packages must stay out of an unselected package set"
fi
if contains homebrew_casks "${selected[@]}"; then
  fail "cask applications must stay out of an unselected package set"
fi

# Chosen packages survive the round trip through the workflow store.
workflow_select_packages homebrew_casks firefox ghostty
casks=()
workflow_selected_packages casks homebrew_casks
[[ "${casks[*]}" == 'firefox ghostty' ]] || fail "chosen casks must be read back"

# The cask command is handed to the direct-input finish handler.
catalog_finish_handler finish_handler homebrew_casks
[[ "$finish_handler" == action_install_homebrew_casks ]] || \
  fail "cask installation must use the direct-input finish handler"
cask_command="$(
  executor_brew() {
    [[ "${HOMEBREW_NO_INSTALL_UPGRADE:-}" == 1 ]] || return 1
    printf '%s\n' "$*"
  }
  status_report() { :; }
  workflow_select_packages homebrew_casks firefox bitwarden
  action_install_homebrew_casks macos ''
)"
[[ "$cask_command" == 'install --cask firefox bitwarden' ]] || \
  fail "cask installation must use only selected packages"

formula_command="$(
  executor_brew() {
    [[ "${HOMEBREW_NO_INSTALL_UPGRADE:-}" == 1 ]] || return 1
    printf '%s\n' "$*"
  }
  workflow_select_packages homebrew_extended tmux fzf
  action_install_homebrew_extended fedora ''
)"
[[ "$formula_command" == 'install tmux fzf' ]] || \
  fail "formula installation must use only selected packages"

# Failed probes must not publish partial results or retain stale values.
(
  failing_installed_probe() {
    local -n found_ref="$1"
    found_ref=(tmux)
    return 9
  }
  procedure_installed_probe homebrew_extended failing_installed_probe
  installed=(stale)
  actual=0
  workflow_installed_packages installed homebrew_extended tmux || actual=$?
  [[ "$actual" == 9 && "${#installed[@]}" == 0 ]] || \
    fail "failed probes must propagate status and discard partial results"
)

# Native requirements follow selected consumers and are deduplicated.
SETUP_MODE=standard
workflow_reset
workflow_select homebrew yes
workflow_select homebrew_extended yes
workflow_select_packages homebrew_extended sdkman-cli
workflow_native_requirements needs consumers debian all
[[ "${needs[*]}" == NATIVE_BUILD_TOOLS && "${consumers[*]}" == sdkman-cli ]] ||
  fail "SDKMAN should request Debian build tools"
workflow_native_requirements needs consumers macos all
[[ "${#needs[@]}" == 0 ]] || fail "macOS should not request native build tools"
workflow_select_packages homebrew_extended tmux
workflow_native_requirements needs consumers debian all
[[ "${#needs[@]}" == 0 ]] || fail "other Brew formulae should not request build tools"
workflow_reset
workflow_select yay yes
yay_is_installed() { return 1; }
workflow_select homebrew yes
workflow_select homebrew_extended yes
workflow_select_packages homebrew_extended sdkman-cli
workflow_native_requirements needs consumers arch all
[[ "${needs[*]}" == NATIVE_BUILD_TOOLS && "${#needs[@]}" == 1 ]] ||
  fail "yay and SDKMAN should share one Arch build-tool requirement"

workflow_select homebrew_extended no
workflow_native_requirements needs consumers arch all
[[ "${needs[*]}" == NATIVE_BUILD_TOOLS && "${consumers[*]}" == yay ]] ||
  fail "missing yay should request build tools"
yay_is_installed() { return 0; }
workflow_native_requirements needs consumers arch all
[[ "${#needs[@]}" == 0 ]] || fail "installed yay should not request build tools"
workflow_select homebrew_extended yes
workflow_native_requirements needs consumers arch all
[[ "${needs[*]}" == NATIVE_BUILD_TOOLS && "${consumers[*]}" == sdkman-cli ]] ||
  fail "installed yay must not suppress SDKMAN build tools"

printf 'Workflow validation passed.\n'
