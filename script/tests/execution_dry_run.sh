#!/usr/bin/env bash
set -Eeuo pipefail

test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
script_root="$(cd -- "${test_dir}/.." && pwd)"
distribution_family="${1:-}"

case "$distribution_family" in
  arch | debian | fedora)
    ;;
  *)
    printf 'Usage: %s {arch|debian|fedora}\n' "$0" >&2
    exit 2
    ;;
esac

export SETUP_DRY_RUN=1

# shellcheck source=../lib/ui.sh
source "${script_root}/lib/ui.sh"
# shellcheck source=../lib/steps.sh
source "${script_root}/lib/steps.sh"
# shellcheck source=../config/steps.sh
source "${script_root}/config/steps.sh"
# shellcheck source=../lib/execution.sh
source "${script_root}/lib/execution.sh"

distribution_name="Dry-run ${distribution_family}"

steps_validate

for step_id in "${STEP_IDS[@]}"; do
  if steps_is_available "$step_id" "$distribution_family"; then
    STEP_SELECTED["$step_id"]="yes"
  fi
done

execution_run_selected
