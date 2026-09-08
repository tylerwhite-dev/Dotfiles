#!/usr/bin/env bash
set -Eeuo pipefail

setup_started_at=$SECONDS
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/renderer.sh
source "${script_dir}/lib/renderer.sh"

renderer_run "$@"

setup_elapsed_seconds=$((SECONDS - setup_started_at))
setup_elapsed_minutes=$((setup_elapsed_seconds / 60))
setup_elapsed_seconds=$((setup_elapsed_seconds % 60))

if ((setup_elapsed_minutes > 0)); then
  printf '\nSetup completed in %dm %02ds.\n' \
    "$setup_elapsed_minutes" "$setup_elapsed_seconds"
else
  printf '\nSetup completed in %ds.\n' "$setup_elapsed_seconds"
fi
