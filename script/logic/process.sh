#!/usr/bin/env bash

# Renders the final timeline row and returns the action status unchanged.
_process_finish() {
  local status="$1"
  local label="$2"
  local started_at="$3"

  ui_timeline_finished "$status" "$label" "$((SECONDS - started_at))"
  return "$status"
}

# Runs one action without a coprocess or animated redraw.
_process_run_plain() {
  local handler="$1"
  local current="$2"
  local total="$3"
  local label="$4"
  local platform="$5"
  local repository_dir="$6"
  local finish_handler="$7"
  local started_at="$SECONDS"
  local status

  ui_timeline_active "$current" "$total" "$label" 0 '◉' no
  printf '\n'

  if "$handler" "$platform" "$repository_dir"; then
    status=0
  else
    status=$?
  fi

  if ((status == 0)) && [[ -n "$finish_handler" ]]; then
    if "$finish_handler" "$platform" "$repository_dir"; then
      status=0
    else
      status=$?
    fi
  fi

  _process_finish "$status" "$label" "$started_at"
}

# Redraws the active timeline while forwarding lines from an action's output.
_process_render_output() {
  local output_fd="$1"
  local current="$2"
  local total="$3"
  local label="$4"
  local started_at="$5"
  local started_at_microseconds="$6"
  local now_microseconds
  local elapsed_microseconds
  local frame
  local line
  local read_status

  while true; do
    now_microseconds="${EPOCHREALTIME/./}"
    elapsed_microseconds=$((now_microseconds - started_at_microseconds))
    ui_timeline_frame frame "$elapsed_microseconds"
    ui_timeline_active \
      "$current" "$total" "$label" "$((SECONDS - started_at))" "$frame" yes

    line=""
    if IFS= read -r -t 0.08 -u "$output_fd" line 2>/dev/null; then
      ui_timeline_output "$line"
      continue
    else
      read_status=$?
    fi

    if [[ -n "$line" ]]; then
      ui_timeline_output "$line"
    fi
    if ((read_status < 128)); then
      return 0
    fi
  done
}

# Runs one action in a coprocess and waits for its animated output to finish.
_process_run_animated() {
  local handler="$1"
  local current="$2"
  local total="$3"
  local label="$4"
  local platform="$5"
  local repository_dir="$6"
  local finish_handler="$7"
  local started_at="$SECONDS"
  local started_at_microseconds="${EPOCHREALTIME/./}"
  local process_pid
  local output_fd
  local status

  unset setup_procedure_process setup_procedure_process_PID 2>/dev/null || true
  coproc setup_procedure_process {
    "$handler" "$platform" "$repository_dir" </dev/tty 2>&1
  }
  process_pid="$setup_procedure_process_PID"
  exec {output_fd}<&"${setup_procedure_process[0]}"

  _process_render_output \
    "$output_fd" "$current" "$total" "$label" \
    "$started_at" "$started_at_microseconds"
  ui_timeline_clear
  if wait "$process_pid"; then
    status=0
  else
    status=$?
  fi

  exec {output_fd}<&- 2>/dev/null || true
  unset setup_procedure_process setup_procedure_process_PID 2>/dev/null || true

  if ((status == 0)) && [[ -n "$finish_handler" ]]; then
    if "$finish_handler" "$platform" "$repository_dir"; then
      status=0
    else
      status=$?
    fi
  fi

  _process_finish "$status" "$label" "$started_at"
}

# Adds privilege preparation and selects plain or animated action execution.
process_run() {
  local handler="$1"
  local current="$2"
  local total="$3"
  local label="$4"
  local requires_root="$5"
  local platform="$6"
  local repository_dir="$7"
  local finish_handler="$8"
  local started_at="$SECONDS"

  if [[ "$requires_root" == "yes" ]]; then
    if ((EUID != 0)) && ! sudo -n -v >/dev/null 2>&1; then
      status_report status.sudo_auth_prompt "$label"
    fi
    if ! executor_prepare_privilege; then
      _process_finish 1 "$label" "$started_at"
      return 1
    fi
  fi

  if ! ui_is_interactive; then
    _process_run_plain \
      "$handler" "$current" "$total" "$label" "$platform" "$repository_dir" "$finish_handler"
  else
    _process_run_animated \
      "$handler" "$current" "$total" "$label" "$platform" "$repository_dir" "$finish_handler"
  fi
}
