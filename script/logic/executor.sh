#!/usr/bin/env bash

_executor_adapter="real"

# Selects the real or dry-run command adapter from SETUP_DRY_RUN.
executor_initialize() {
  local dry_run="${SETUP_DRY_RUN:-0}"

  if [[ "$dry_run" != "0" && "$dry_run" != "1" ]]; then
    error_report error.dry_run_invalid
    return 1
  fi

  if [[ "$dry_run" == "1" ]]; then
    _executor_adapter="dry_run"
  else
    _executor_adapter="real"
  fi
}

# Reports whether command execution is currently in dry-run mode.
executor_is_dry_run() {
  [[ "$_executor_adapter" == "dry_run" ]]
}

# Prints a command and dispatches it through the selected adapter.
executor_run() {
  ui_command "$@"
  "_executor_${_executor_adapter}_run" "$@"
}

# Checks a command without requiring it to exist during a dry run.
executor_require() {
  local command="$1"

  if executor_is_dry_run || command -v "$command" >/dev/null 2>&1; then
    return 0
  fi

  error_report error.command_missing "$command"
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
  if executor_is_dry_run || ((EUID == 0)); then
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

# Returns a temporary-file path from the selected executor adapter.
executor_temp_file() {
  "_executor_${_executor_adapter}_temp_file"
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
