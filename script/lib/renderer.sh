#!/usr/bin/env bash

renderer_root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=ui.sh
source "${renderer_root_dir}/lib/ui.sh"
# shellcheck source=distribution.sh
source "${renderer_root_dir}/lib/distribution.sh"
# shellcheck source=steps.sh
source "${renderer_root_dir}/lib/steps.sh"
# shellcheck source=../config/steps.sh
source "${renderer_root_dir}/config/steps.sh"
# shellcheck source=execution.sh
source "${renderer_root_dir}/lib/execution.sh"
# shellcheck source=questionnaire.sh
source "${renderer_root_dir}/lib/questionnaire.sh"

renderer_run() {
  if ! ui_is_interactive; then
    ui_print_error "An interactive terminal is required."
    exit 1
  fi

  ui_print_heading "System setup"

  if ! steps_validate; then
    ui_print_error "Could not load the setup steps."
    exit 1
  fi

  distribution_require_supported || exit 1

  while true; do
    questionnaire_collect_answers

    if questionnaire_confirm_answers; then
      break
    fi
  done

  ui_print_success "Settings confirmed."
  execution_run_selected
}
