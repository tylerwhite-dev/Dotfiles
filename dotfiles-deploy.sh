#!/usr/bin/env bash

if (( ${BASH_VERSINFO[0]:-0} < 5 )); then
  printf 'This script requires bash 5 or newer (found %s).\n' "${BASH_VERSION:-unknown}" >&2
  printf 'On macOS install it with: brew install bash\n' >&2
  printf 'Then run: /opt/homebrew/bin/bash dotfiles-deploy.sh\n' >&2
  exit 1
fi

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=logic/load.sh
source "${script_dir}/script/logic/load.sh"

flags_parse "$@"
setup_run "$@"
