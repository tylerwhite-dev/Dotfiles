#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/renderer.sh
source "${script_dir}/lib/renderer.sh"

renderer_run "$@"
