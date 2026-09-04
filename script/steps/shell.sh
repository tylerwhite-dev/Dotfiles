#!/usr/bin/env bash

execution_set_zsh_default() {
  local current_user="${SUDO_USER:-${USER:-}}"

  if [[ -z "$current_user" ]]; then
    ui_print_error "Could not determine the current user."
    return 1
  fi

  if [[ "$execution_dry_run" != "1" && ! -x /bin/zsh ]]; then
    ui_print_error "Zsh is not installed at /bin/zsh."
    return 1
  fi

  execution_run_as_root chsh -s /bin/zsh "$current_user"
}
