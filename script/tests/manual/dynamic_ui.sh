#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=../../ui/ui.sh
source "${script_root}/ui/ui.sh"
# shellcheck source=ui_lib.sh
source "${script_root}/tests/manual/ui_lib.sh"
# shellcheck source=cases_dynamic_ui.sh
source "${script_root}/tests/manual/cases_dynamic_ui.sh"

main() {
  local mode="${1:-all}"

  if [[ "$mode" == "--list" ]]; then
    printf 'Available tests:\n'
    printf '  ui_select\n'
    printf '  ui_multiselect\n'
    exit 0
  fi

  if ! ui_is_interactive; then
    printf 'ERROR: test requires an interactive terminal (stdin/stdout TTY).\n' >&2
    exit 1
  fi

  printf '\n'
  _test_msg "MANUAL UI TEST — DYNAMIC (part 2)"
  printf '  Dynamic elements: interactive controls (yes/no, single choice, checkboxes).\n'
  printf '  [y] pass  [n] fail  [s] skip  [q] quit\n'

  case "$mode" in
    ui_select) run_ui_select ;;
    ui_multiselect) run_ui_multiselect ;;
    all|"")
      run_ui_select
      run_ui_multiselect
      ;;
    *)
      printf 'Unknown component: %s\n' "$mode" >&2
      printf 'Usage: %s [ui_select|ui_multiselect|--list]\n' "${BASH_SOURCE[0]}" >&2
      exit 1
      ;;
  esac

  _final_summary
}

main "$@"