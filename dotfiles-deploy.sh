#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=logic/load.sh
source "${script_dir}/script/logic/load.sh"

flags_parse "$@"
setup_run "$@"
