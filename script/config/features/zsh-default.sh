#!/usr/bin/env bash

message_define error.current_user_unknown \
  "Could not determine the current user."

message_define error.zsh_missing \
  "Zsh is not installed at /bin/zsh."

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

procedure_define zsh_default
procedure_handler zsh_default action_set_zsh_default
procedure_platforms zsh_default arch debian fedora
procedure_requires_root zsh_default arch debian fedora
message_define procedure.zsh_default.question "Set zsh as the default shell?"
message_define procedure.zsh_default.label "Set zsh as the default shell"
message_define procedure.zsh_default.description \
  "The current user's login shell will be changed to /bin/zsh."
