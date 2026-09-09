#!/usr/bin/env bash

ui_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=theme.sh
source "${ui_dir}/theme.sh"
# shellcheck source=terminal.sh
source "${ui_dir}/terminal.sh"
# shellcheck source=menu.sh
source "${ui_dir}/menu.sh"
# shellcheck source=stage.sh
source "${ui_dir}/stage.sh"
# shellcheck source=timeline.sh
source "${ui_dir}/timeline.sh"

unset ui_dir
