#!/usr/bin/env bash

# Truncates a procedure label to fit the current terminal width.
_ui_timeline_truncate_label() {
  local __ui_tl_columns="${COLUMNS:-80}" __ui_tl_reserved="${3:-32}"
  [[ "$__ui_tl_columns" =~ ^[1-9][0-9]*$ ]] || __ui_tl_columns=80
  _ui_truncate "$1" "$2" "$((10#$__ui_tl_columns-__ui_tl_reserved-1))"
}

# Formats elapsed seconds as a compact clock label.
_ui_timeline_format_timer() {
  local result_name="$1"
  local elapsed_seconds="$2"
  local hours=$((elapsed_seconds / 3600))
  local minutes=$(((elapsed_seconds % 3600) / 60))
  local seconds=$((elapsed_seconds % 60))

  if ((hours > 0)); then
    printf -v "$result_name" '%02d:%02d:%02d' "$hours" "$minutes" "$seconds"
  else
    printf -v "$result_name" '%02d:%02d' "$minutes" "$seconds"
  fi
}

# Formats elapsed seconds as a human-readable completion duration.
_ui_timeline_format_duration() {
  local result_name="$1"
  local elapsed_seconds="$2"
  local hours=$((elapsed_seconds / 3600))
  local minutes=$(((elapsed_seconds % 3600) / 60))
  local seconds=$((elapsed_seconds % 60))

  if ((hours > 0)); then
    printf -v "$result_name" '%dh %02dm %02ds' "$hours" "$minutes" "$seconds"
  elif ((minutes > 0)); then
    printf -v "$result_name" '%dm %02ds' "$minutes" "$seconds"
  else
    printf -v "$result_name" '%ds' "$seconds"
  fi
}

# Selects an animation frame from elapsed microseconds.
ui_timeline_frame() {
  _ui_output_name "$1" || return
  local __ui_frame_result_name="$1"
  local __ui_frame_elapsed_microseconds="$2"
  local __ui_frame_frame_count="${#ui_timeline_frames[@]}"
  local __ui_frame_frame_index=$((__ui_frame_elapsed_microseconds / ui_timeline_frame_microseconds))

  printf -v "$__ui_frame_result_name" '%s' \
    "${ui_timeline_frames[__ui_frame_frame_index % __ui_frame_frame_count]}"
}

# Renders the current procedure marker, progress, label, and timer.
ui_timeline_active() {
  local current="$1"
  local total="$2"
  local label="$3"
  local elapsed_seconds="$4"
  local marker="$5"
  local redraw="$6"
  local rendered_label
  local timer_label
  local progress_label
  local redraw_prefix=''

  _ui_timeline_format_timer timer_label "$elapsed_seconds"
  printf -v progress_label '%02d / %02d' "$current" "$total"
  _ui_timeline_truncate_label rendered_label "$label" \
    "$((${#marker}+${#progress_label}+${#timer_label}+6))"

  if [[ "$redraw" == "yes" ]]; then
    redraw_prefix=$'\r\033[2K'
  fi

  printf '%s%s%s%s  %s%s%s  %s  %s%s%s' \
    "$redraw_prefix" "$ui_color_comment" "$marker" "$ui_color_reset" \
    "$ui_color_heading" "$progress_label" "$ui_color_reset" \
    "$rendered_label" \
    "$ui_color_hint" "$timer_label" "$ui_color_reset"
}

# Writes an action output line below the active timeline row.
ui_timeline_output() {
  local line="${1##*$'\r'}"

  printf '\r\033[2K%s│%s  %s\n' \
    "$ui_color_hint" "$ui_color_reset" "$line"
}

# Clears the currently redrawn timeline row.
ui_timeline_clear() {
  printf '\r\033[2K'
}

# Renders the final success or failure row with its duration.
ui_timeline_finished() {
  local status="$1"
  local label="$2"
  local elapsed_seconds="$3"
  local rendered_label
  local duration_label
  local symbol
  local symbol_color

  _ui_timeline_format_duration duration_label "$elapsed_seconds"

  if ((status == 0)); then
    symbol='●'
    symbol_color="$ui_color_success"
  else
    symbol='×'
    symbol_color="$ui_color_error"
  fi

  _ui_timeline_truncate_label rendered_label "$label" \
    "$((${#symbol}+${#duration_label}+4))"

  printf '%s%s%s  %s  %s%s%s\n' \
    "$symbol_color" "$symbol" "$ui_color_reset" \
    "$rendered_label" \
    "$ui_color_hint" "$duration_label" "$ui_color_reset"
}
