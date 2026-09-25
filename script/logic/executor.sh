#!/usr/bin/env bash

# Prints and executes a command.
executor_run() {
  ui_command "$@"
  "$@"
}

# Checks that a required command exists.
executor_require() {
  local command="$1"

  if command -v "$command" >/dev/null 2>&1; then
    return 0
  fi

  error_report error.command_missing "$command"
  return 1
}

# Resolves a command from PATH or the configured Homebrew bin directory.
executor_resolve_command() {
  local -n result_ref="$1"
  local command_name="$2"
  local brew_bin
  local brew_command

  if command -v "$command_name" >/dev/null 2>&1; then
    result_ref="$command_name"
    return 0
  fi

  brew_bin="$(executor_brew_bin)" || return
  brew_command="${brew_bin%/*}/${command_name}"
  if [[ -x "$brew_command" ]]; then
    result_ref="$brew_command"
    return 0
  fi

  error_report error.command_missing "$command_name"
  return 1
}

# Builds a command prefixed with sudo when the current user is not root.
_executor_root_command() {
  local -n result_ref="$1"
  shift

  if ((EUID == 0)); then
    result_ref=("$@")
  else
    executor_require sudo || return
    result_ref=(sudo "$@")
  fi
}

# Runs a command with the privilege prefix selected by _executor_root_command.
executor_run_as_root() {
  local -a command=()
  _executor_root_command command "$@" || return
  executor_run "${command[@]}"
}

# Retries a command after failures, reporting each retry to the user.
executor_retry() {
  local attempts="$1"
  local delay_seconds="$2"
  shift 2

  local attempt
  local retry_message

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if executor_run "$@"; then
      return 0
    fi

    if ((attempt < attempts)); then
      message_format retry_message status.retry \
        "$delay_seconds" "$attempt" "$attempts"
      ui_notice "$retry_message"
      sleep "$delay_seconds"
    fi
  done

  return 1
}

# Combines root command construction with executor_retry.
executor_retry_as_root() {
  local attempts="$1"
  local delay_seconds="$2"
  shift 2

  local -a command=()
  _executor_root_command command "$@" || return
  executor_retry "$attempts" "$delay_seconds" "${command[@]}"
}

# Refreshes the sudo timestamp when a later action needs root access.
executor_prepare_privilege() {
  if ((EUID == 0)); then
    return 0
  fi

  executor_require sudo || return
  sudo -v
}

# Downloads a URL through curl using the command execution seam.
executor_download() {
  local url="$1"
  local destination="$2"

  executor_require curl || return
  executor_run curl \
    --fail \
    --location \
    --connect-timeout 20 \
    --retry 3 \
    --retry-all-errors \
    --retry-delay 5 \
    --output "$destination" \
    "$url"
}

# Creates a unique temporary file for command execution.
executor_temp_file() {
  mktemp "${TMPDIR:-/tmp}/dotfiles-setup.XXXXXX"
}

# Returns the Homebrew binary path for the current platform.
executor_brew_bin() {
  case "${OSTYPE:-}" in
    darwin*)
      if [[ -x /opt/homebrew/bin/brew ]]; then
        printf '%s\n' /opt/homebrew/bin/brew
      elif [[ -x /usr/local/bin/brew ]]; then
        printf '%s\n' /usr/local/bin/brew
      elif [[ "$(uname -m)" == "arm64" ]]; then
        printf '%s\n' /opt/homebrew/bin/brew
      else
        printf '%s\n' /usr/local/bin/brew
      fi
      ;;
    *)
      printf '%s\n' "$SETUP_BREW_BIN"
      ;;
  esac
}

# Runs a Homebrew command with stable no-prompt and retry settings.
executor_brew() {
  local brew_bin
  brew_bin="$(executor_brew_bin)"

  executor_retry "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" env \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_ASK=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_CURL_RETRIES=3 \
    "$brew_bin" "$@"
}
