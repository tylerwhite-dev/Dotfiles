#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=logic/load.sh
source "${script_dir}/logic/load.sh"

setup_run "$@"
