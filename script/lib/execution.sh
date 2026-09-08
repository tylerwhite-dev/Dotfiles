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

execution_spinner_frames=('◌' '○' '◎' '◉' '●' '◉' '◎' '○')
execution_spinner_frame_microseconds=150000
EXECUTION_RENDERED_LABEL=""
EXECUTION_TIMER_LABEL=""
EXECUTION_DURATION_LABEL=""

execution_truncate_step_label() {
  local label="$1"
  local terminal_columns="${COLUMNS:-80}"
  local maximum_length

  if [[ ! "$terminal_columns" =~ ^[0-9]+$ ]]; then
    terminal_columns=80
  fi

  maximum_length=$((terminal_columns - 32))
  if ((maximum_length < 20)); then
    maximum_length=20
  fi

  if ((${#label} > maximum_length)); then
    EXECUTION_RENDERED_LABEL="${label:0:maximum_length-1}…"
  else
    EXECUTION_RENDERED_LABEL="$label"
  fi
}

execution_format_timer() {
  local elapsed_seconds="$1"
  local hours=$((elapsed_seconds / 3600))
  local minutes=$(((elapsed_seconds % 3600) / 60))
  local seconds=$((elapsed_seconds % 60))

  if ((hours > 0)); then
    printf -v EXECUTION_TIMER_LABEL '%02d:%02d:%02d' \
      "$hours" "$minutes" "$seconds"
  else
    printf -v EXECUTION_TIMER_LABEL '%02d:%02d' "$minutes" "$seconds"
  fi
}

execution_format_duration() {
  local elapsed_seconds="$1"
  local hours=$((elapsed_seconds / 3600))
  local minutes=$(((elapsed_seconds % 3600) / 60))
  local seconds=$((elapsed_seconds % 60))

  if ((hours > 0)); then
    printf -v EXECUTION_DURATION_LABEL '%dh %02dm %02ds' \
      "$hours" "$minutes" "$seconds"
  elif ((minutes > 0)); then
    printf -v EXECUTION_DURATION_LABEL '%dm %02ds' "$minutes" "$seconds"
  else
    printf -v EXECUTION_DURATION_LABEL '%ds' "$seconds"
  fi
}

execution_print_stage_heading() {
  local selected_count="$1"

  printf '\n%sSTART RUN%s\n' \
    "$ui_color_execution_heading" "$ui_color_reset"
  printf '%s%s%s\n' \
    "$ui_color_execution_heading" \
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' \
    "$ui_color_reset"
  printf '%s%s · %d steps selected%s\n\n' \
    "$ui_color_hint" "$distribution_name" "$selected_count" "$ui_color_reset"
}

execution_print_active_step() {
  local current="$1"
  local total="$2"
  local label="$3"
  local elapsed_seconds="$4"
  local marker="${5:-◉}"
  local redraw="${6:-yes}"

  execution_truncate_step_label "$label"
  execution_format_timer "$elapsed_seconds"

  if [[ "$redraw" == "yes" ]]; then
    printf '\r\033[2K'
  fi

  printf '%s%s%s  %s%02d / %02d%s  %s  %s%s%s' \
    "$ui_color_comment" "$marker" "$ui_color_reset" \
    "$ui_color_execution_heading" "$current" "$total" "$ui_color_reset" \
    "$EXECUTION_RENDERED_LABEL" \
    "$ui_color_hint" "$EXECUTION_TIMER_LABEL" "$ui_color_reset"
}

execution_print_finished_step() {
  local symbol="$1"
  local symbol_color="$2"
  local label="$3"
  local elapsed_seconds="$4"

  execution_truncate_step_label "$label"
  execution_format_duration "$elapsed_seconds"

  printf '%s%s%s  %s  %s%s%s\n' \
    "$symbol_color" "$symbol" "$ui_color_reset" \
    "$EXECUTION_RENDERED_LABEL" \
    "$ui_color_hint" "$EXECUTION_DURATION_LABEL" "$ui_color_reset"
}

execution_print_step_output() {
  local line="${1##*$'\r'}"

  printf '\r\033[2K%s│%s  %s\n' \
    "$ui_color_hint" "$ui_color_reset" "$line"
}

execution_step_uses_sudo() {
  local command="$1"
  local definition

  definition="$(declare -f "$command")" || return 1
  [[ "$definition" == *execution_run_as_root* || \
    "$definition" == *execution_retry_as_root* ]]
}

execution_prepare_step_input() {
  local command="$1"

  if [[ "$execution_dry_run" == "1" ]] || ((EUID == 0)) || \
    ! execution_step_uses_sudo "$command"; then
    return 0
  fi

  execution_require_command sudo || return
  sudo -v
}

execution_run_step_animated() {
  local command="$1"
  local current="$2"
  local total="$3"
  local label="$4"
  local started_at="$SECONDS"
  local frame_index=0
  local frame_count="${#execution_spinner_frames[@]}"
  local frame_started_at="${EPOCHREALTIME/./}"
  local frame
  local frame_elapsed_microseconds
  local frame_advance
  local now_microseconds
  local line=""
  local read_status
  local process_pid
  local output_fd
  local status

  unset execution_step_process execution_step_process_PID 2>/dev/null || true
  coproc execution_step_process { "$command" </dev/tty 2>&1; }
  process_pid="$execution_step_process_PID"
  exec {output_fd}<&"${execution_step_process[0]}"

  while true; do
    now_microseconds="${EPOCHREALTIME/./}"
    frame_elapsed_microseconds=$((now_microseconds - frame_started_at))
    if ((frame_elapsed_microseconds >= execution_spinner_frame_microseconds)); then
      frame_advance=$((frame_elapsed_microseconds / execution_spinner_frame_microseconds))
      ((frame_index += frame_advance))
      ((frame_started_at += frame_advance * execution_spinner_frame_microseconds))
    fi

    frame="${execution_spinner_frames[frame_index % frame_count]}"
    execution_print_active_step \
      "$current" "$total" "$label" "$((SECONDS - started_at))" "$frame"

    line=""
    if IFS= read -r -t 0.08 -u "$output_fd" line 2>/dev/null; then
      execution_print_step_output "$line"
      continue
    else
      read_status=$?
    fi

    if [[ -n "$line" ]]; then
      execution_print_step_output "$line"
    fi

    if ((read_status < 128)); then
      break
    fi
  done

  printf '\r\033[2K'

  if wait "$process_pid"; then
    status=0
  else
    status=$?
  fi

  exec {output_fd}<&- 2>/dev/null || true
  unset execution_step_process execution_step_process_PID 2>/dev/null || true

  if ((status == 0)); then
    execution_print_finished_step \
      '●' "$ui_color_success" "$label" \
      "$((SECONDS - started_at))"
  else
    execution_print_finished_step \
      '×' "$ui_color_error" "$label" \
      "$((SECONDS - started_at))"
  fi

  return "$status"
}

execution_run_step_plain() {
  local command="$1"
  local current="$2"
  local total="$3"
  local label="$4"
  local started_at="$SECONDS"
  local status

  execution_print_active_step \
    "$current" "$total" "$label" 0 "" no
  printf '\n'

  if "$command"; then
    status=0
  else
    status=$?
  fi

  if ((status == 0)); then
    execution_print_finished_step \
      '●' "$ui_color_success" "$label" \
      "$((SECONDS - started_at))"
  else
    execution_print_finished_step \
      '×' "$ui_color_error" "$label" \
      "$((SECONDS - started_at))"
  fi

  return "$status"
}

execution_run_step() {
  local command="$1"
  local current="$2"
  local total="$3"
  local label="$4"
  local started_at="$SECONDS"

  if ! execution_prepare_step_input "$command"; then
    execution_print_finished_step \
      '×' "$ui_color_error" "$label" \
      "$((SECONDS - started_at))"
    return 1
  fi

  if [[ "$execution_dry_run" == "1" || ! -t 0 || ! -t 1 ]]; then
    execution_run_step_plain "$command" "$current" "$total" "$label"
  else
    execution_run_step_animated "$command" "$current" "$total" "$label"
  fi
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

  execution_print_stage_heading "$selected_count"

  for step_id in "${STEP_IDS[@]}"; do
    if [[ "${STEP_SELECTED[$step_id]}" != "yes" ]] || \
      ! steps_is_available "$step_id" "$distribution_family"; then
      continue
    fi

    ((current += 1))
    command="${STEP_COMMAND[$step_id]}"

    if ! execution_run_step \
      "$command" "$current" "$selected_count" "${STEP_QUESTION[$step_id]%\?}"; then
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
