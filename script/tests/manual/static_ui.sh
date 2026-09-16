#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=../../ui/ui.sh
source "${script_root}/ui/ui.sh"
# shellcheck source=ui_lib.sh
source "${script_root}/tests/manual/ui_lib.sh"
# shellcheck source=cases_static_ui.sh
source "${script_root}/tests/manual/cases_static_ui.sh"

main() {
  local mode="${1:-all}"

  if [[ "$mode" == "--list" ]]; then
    printf 'Available tests:\n'
    printf '  ui_stage\n'
    printf '  ui_summary_item\n'
    printf '  ui_summary_item_packages\n'
    printf '  ui_timeline_active\n'
    printf '  ui_timeline_finished\n'
    printf '  ui_timeline_output\n'
    exit 0
  fi

  if ! ui_is_interactive; then
    printf 'ERROR: test requires an interactive terminal (stdin/stdout TTY).\n' >&2
    exit 1
  fi

  printf '\n'
  _test_msg "MANUAL UI TEST — STATIC (part 1)"
  printf '  Static elements: rendered output, no user interaction.\n'
  printf '  [y] pass  [n] fail  [s] skip  [q] quit\n'

  case "$mode" in
    ui_stage) run_ui_stage ;;
    ui_summary_item) run_ui_summary_item ;;
    ui_summary_item_packages) run_ui_summary_item_packages ;;
    ui_timeline_active) run_ui_timeline_active ;;
    ui_timeline_finished) run_ui_timeline_finished ;;
    ui_timeline_output) run_ui_timeline_output ;;
    all|"")
      run_ui_stage
      run_ui_summary_item
      run_ui_summary_item_packages
      run_ui_timeline_active
      run_ui_timeline_finished
      run_ui_timeline_output
      ;;
    *)
      printf 'Unknown component: %s\n' "$mode" >&2
      printf 'Usage: %s [ui_stage|ui_summary_item|ui_summary_item_packages|ui_timeline_active|ui_timeline_finished|ui_timeline_output|--list]\n' "${BASH_SOURCE[0]}" >&2
      exit 1
      ;;
  esac

  _final_summary
}

main "$@"