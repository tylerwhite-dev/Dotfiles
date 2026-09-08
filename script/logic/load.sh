#!/usr/bin/env bash

SETUP_SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_REPOSITORY_ROOT="$(cd -- "${SETUP_SCRIPT_ROOT}/.." && pwd)"

# Core declaration interfaces.
# shellcheck source=messages.sh
source "${SETUP_SCRIPT_ROOT}/logic/messages.sh"
# shellcheck source=catalog.sh
source "${SETUP_SCRIPT_ROOT}/logic/catalog.sh"

# Rendering interface.
# shellcheck source=../ui/ui.sh
source "${SETUP_SCRIPT_ROOT}/ui/ui.sh"

# Business modules.
# shellcheck source=errors.sh
source "${SETUP_SCRIPT_ROOT}/logic/errors.sh"
# shellcheck source=environment.sh
source "${SETUP_SCRIPT_ROOT}/logic/environment.sh"
# shellcheck source=executors/real.sh
source "${SETUP_SCRIPT_ROOT}/logic/executors/real.sh"
# shellcheck source=executors/dry-run.sh
source "${SETUP_SCRIPT_ROOT}/logic/executors/dry-run.sh"
# shellcheck source=executor.sh
source "${SETUP_SCRIPT_ROOT}/logic/executor.sh"
# shellcheck source=workflow.sh
source "${SETUP_SCRIPT_ROOT}/logic/workflow.sh"
# shellcheck source=questionnaire.sh
source "${SETUP_SCRIPT_ROOT}/logic/questionnaire.sh"
# shellcheck source=process.sh
source "${SETUP_SCRIPT_ROOT}/logic/process.sh"
# shellcheck source=runner.sh
source "${SETUP_SCRIPT_ROOT}/logic/runner.sh"

# Configuration declarations.
# shellcheck source=../config/settings.sh
source "${SETUP_SCRIPT_ROOT}/config/settings.sh"
# shellcheck source=../config/messages.sh
source "${SETUP_SCRIPT_ROOT}/config/messages.sh"
# shellcheck source=../config/packages.sh
source "${SETUP_SCRIPT_ROOT}/config/packages.sh"

# Procedure actions. New files are loaded automatically.
setup_action_files=("${SETUP_SCRIPT_ROOT}"/logic/actions/*.sh)
if [[ ! -e "${setup_action_files[0]}" ]]; then
  printf 'No procedure actions were found.\n' >&2
  return 1 2>/dev/null || exit 1
fi
for setup_action_file in "${setup_action_files[@]}"; do
  # shellcheck source=/dev/null
  source "$setup_action_file"
done
unset setup_action_file setup_action_files

# Procedure declarations reference the loaded action names.
# shellcheck source=../config/procedures.sh
source "${SETUP_SCRIPT_ROOT}/config/procedures.sh"

# Top-level application flow.
# shellcheck source=app.sh
source "${SETUP_SCRIPT_ROOT}/logic/app.sh"
