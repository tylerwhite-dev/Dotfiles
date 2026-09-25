#!/usr/bin/env bash

# Changes the current user's login shell to /bin/zsh with root privileges.
action_set_zsh_default() {
  local current_user="${SUDO_USER:-${USER:-}}"

  if [[ -z "$current_user" ]]; then
    current_user="$(id -un 2>/dev/null)" || current_user=""
  fi

  if [[ -z "$current_user" ]]; then
    error_report error.current_user_unknown
    return 1
  fi

  if [[ ! -x /bin/zsh ]]; then
    error_report error.zsh_missing
    return 1
  fi

  executor_run_as_root chsh -s /bin/zsh "$current_user"
}
