#!/usr/bin/env bash

execution_root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
execution_repository_dir="$(cd -- "${execution_root_dir}/.." && pwd)"
execution_dry_run="${SETUP_DRY_RUN:-0}"
execution_brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"

execution_print_command() {
  local argument

  printf '  +'
  for argument in "$@"; do
    printf ' %q' "$argument"
  done
  printf '\n'
}

execution_run() {
  execution_print_command "$@"

  if [[ "$execution_dry_run" == "1" ]]; then
    return 0
  fi

  "$@"
}

execution_require_command() {
  local command="$1"

  if [[ "$execution_dry_run" == "1" ]] || command -v "$command" >/dev/null 2>&1; then
    return 0
  fi

  ui_print_error "Required command not found: ${command}"
  return 1
}

execution_run_as_root() {
  if ((EUID == 0)); then
    execution_run "$@"
    return
  fi

  execution_require_command sudo || return
  execution_run sudo "$@"
}

execution_retry_as_root() {
  local attempts="$1"
  local delay_seconds="$2"
  shift 2

  if ((EUID == 0)); then
    execution_retry "$attempts" "$delay_seconds" "$@"
    return
  fi

  execution_require_command sudo || return
  execution_retry "$attempts" "$delay_seconds" sudo "$@"
}

execution_retry() {
  local attempts="$1"
  local delay_seconds="$2"
  shift 2

  local attempt

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if execution_run "$@"; then
      return 0
    fi

    if ((attempt < attempts)); then
      printf 'Command failed. Retrying in %s seconds (%s/%s).\n' \
        "$delay_seconds" "$attempt" "$attempts"
      sleep "$delay_seconds"
    fi
  done

  return 1
}

execution_download() {
  local url="$1"
  local destination="$2"

  execution_require_command curl || return
  execution_run curl \
    --fail \
    --location \
    --connect-timeout 20 \
    --retry 3 \
    --retry-all-errors \
    --retry-delay 5 \
    --output "$destination" \
    "$url"
}

execution_temp_file() {
  if [[ "$execution_dry_run" == "1" ]]; then
    printf '/tmp/dotfiles-setup-dry-run'
    return 0
  fi

  mktemp "${TMPDIR:-/tmp}/dotfiles-setup.XXXXXX"
}

execution_brew() {
  execution_retry 4 15 env \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_ASK=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_CURL_RETRIES=3 \
    "$execution_brew_bin" "$@"
}

execution_load_step_implementations() {
  local implementation
  local implementations=("${execution_root_dir}"/steps/*.sh)

  if [[ ! -e "${implementations[0]}" ]]; then
    ui_print_error "No execution step implementations were found."
    return 1
  fi

  for implementation in "${implementations[@]}"; do
    # shellcheck source=/dev/null
    source "$implementation"
  done
}

execution_run_selected() {
  local step_id
  local command
  local selected_count=0
  local current=0

  if [[ "$execution_dry_run" != "0" && "$execution_dry_run" != "1" ]]; then
    ui_print_error "SETUP_DRY_RUN must be 0 or 1."
    return 1
  fi

  if [[ "$execution_dry_run" != "1" ]] && ((EUID == 0)); then
    ui_print_error "Run this setup as a regular user. It will request sudo when needed."
    return 1
  fi

  for step_id in "${STEP_IDS[@]}"; do
    if [[ "${STEP_SELECTED[$step_id]}" == "yes" ]] && \
      steps_is_available "$step_id" "$distribution_family"; then
      ((selected_count += 1))
    fi
  done

  if ((selected_count == 0)); then
    ui_print_success "No steps were selected. Nothing to do."
    return 0
  fi

  ui_print_separator
  ui_print_execution_heading "Applying selected settings"

  for step_id in "${STEP_IDS[@]}"; do
    if [[ "${STEP_SELECTED[$step_id]}" != "yes" ]] || \
      ! steps_is_available "$step_id" "$distribution_family"; then
      continue
    fi

    ((current += 1))
    command="${STEP_COMMAND[$step_id]}"
    printf '\n'
    ui_print_execution_heading \
      "[${current}/${selected_count}] ${STEP_QUESTION[$step_id]%\?}"

    if ! "$command"; then
      ui_print_error "Step failed: ${STEP_QUESTION[$step_id]%\?}"
      return 1
    fi
  done

  if [[ "$execution_dry_run" == "1" ]]; then
    ui_print_success "Dry run completed. No changes were made."
  else
    ui_print_success "Setup completed successfully."
  fi
}

execution_load_step_implementations
