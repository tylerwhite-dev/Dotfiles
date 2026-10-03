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

# CLI flag definitions. Loaded after UI so flags can render errors and help.
# shellcheck source=flags.sh
source "${SETUP_SCRIPT_ROOT}/logic/flags.sh"

# Business modules.
# shellcheck source=errors.sh
source "${SETUP_SCRIPT_ROOT}/logic/errors.sh"
# shellcheck source=environment.sh
source "${SETUP_SCRIPT_ROOT}/logic/environment.sh"
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

# Shared configuration.
# shellcheck source=../config/settings.sh
source "${SETUP_SCRIPT_ROOT}/config/settings.sh"
# shellcheck source=../config/messages.sh
source "${SETUP_SCRIPT_ROOT}/config/messages.sh"
# Feature files own packages, messages, handlers and procedure declarations.
_setup_load_features() {
  # Loading order is deterministic; procedure-order.sh controls execution.
  local LC_ALL=C
  local -a files=("${SETUP_SCRIPT_ROOT}"/config/features/*.sh)
  local file status previous_error_trap

  if [[ ! -f "${files[0]}" ]]; then
    printf 'No setup feature configurations were found.\n' >&2
    return 1
  fi

  previous_error_trap="$(trap -p ERR)"
  # Report the file even when errexit stops the caller inside source.
  trap 'printf "Could not load setup feature configuration: %s\n" "$file" >&2' ERR
  for file in "${files[@]}"; do
    # shellcheck source=/dev/null
    source "$file"
    status=$?
    if ((status != 0)); then
      if [[ -n "$previous_error_trap" ]]; then eval "$previous_error_trap"; else trap - ERR; fi
      return "$status"
    fi
  done
  if [[ -n "$previous_error_trap" ]]; then eval "$previous_error_trap"; else trap - ERR; fi
}

_setup_load_features
setup_feature_status=$?
unset -f _setup_load_features
if ((setup_feature_status != 0)); then
  return "$setup_feature_status" 2>/dev/null || exit "$setup_feature_status"
fi
unset setup_feature_status

# Feature IDs are known before the execution queue is declared.
# shellcheck source=../config/procedure-order.sh
source "${SETUP_SCRIPT_ROOT}/config/procedure-order.sh"

# Top-level application flow.
# shellcheck source=app.sh
source "${SETUP_SCRIPT_ROOT}/logic/app.sh"
