#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../logic/load.sh
source "${script_root}/logic/load.sh"

catalog_validate
printf 'Configuration validation passed.\n'
