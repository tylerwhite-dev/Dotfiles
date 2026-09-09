#!/usr/bin/env bash
set -Eeuo pipefail

test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
script_root="$(cd -- "${test_dir}/.." && pwd)"
platform="${1:-}"

case "$platform" in
  arch | debian | fedora)
    ;;
  *)
    printf 'Usage: %s {arch|debian|fedora}\n' "$0" >&2
    exit 2
    ;;
esac

export SETUP_DRY_RUN=1

# shellcheck source=../logic/load.sh
source "${script_root}/logic/load.sh"

catalog_validate
workflow_reset

declare -a procedure_ids=()
catalog_procedure_ids procedure_ids
for procedure_id in "${procedure_ids[@]}"; do
  if catalog_is_available "$procedure_id" "$platform"; then
    is_selectable=""
    catalog_is_selectable is_selectable "$procedure_id"
    if [[ "$is_selectable" == "yes" ]]; then
      workflow_select_packages_all "$procedure_id" "$platform"
    else
      workflow_select "$procedure_id" yes
    fi
  fi
done

runner_run "$platform" "Dry-run ${platform}" "$SETUP_REPOSITORY_ROOT"
