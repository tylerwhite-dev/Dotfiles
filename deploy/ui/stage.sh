#!/usr/bin/env bash

# Prints a stage title, separator, and metadata line.
ui_stage() {
  local title="$1"
  local metadata="$2"

  printf '\n%s%s%s\n' "$ui_color_heading" "$title" "$ui_color_reset"
  printf '%s%s%s\n' \
    "$ui_color_heading" \
    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' \
    "$ui_color_reset"
  printf '%s%s%s\n\n' "$ui_color_hint" "$metadata" "$ui_color_reset"
}

# Shared review-row rendering; wrappers own selection semantics and colors.
_ui_summary_row() {
  printf '%s%s%s  %s  %s\n' "$2" "$1" "$ui_color_reset" "$3" "$4"
}

# Prints one review row with a symbol and colored yes/no answer.
ui_summary_item() {
  local label="$1"
  local selected="$2"
  local yes_label="$3"
  local no_label="$4"
  local symbol
  local symbol_color
  local answer

  if [[ "$selected" == "yes" ]]; then
    symbol='●'
    symbol_color="$ui_color_success"
    answer="${ui_color_success}${yes_label}${ui_color_reset}"
  else
    symbol='○'
    symbol_color="$ui_color_hint"
    answer="${ui_color_error}${no_label}${ui_color_reset}"
  fi

  _ui_summary_row "$symbol" "$symbol_color" "$label" "$answer"
}

# Prints a review row for a package-select procedure with a count status.
ui_summary_item_packages() {
  local label="$1"
  local count="$2"
  local status="$3"
  local symbol
  local symbol_color

  if ((count > 0)); then
    symbol='●'
    symbol_color="$ui_color_success"
    status="${ui_color_success}${status}${ui_color_reset}"
  else
    symbol='○'
    symbol_color="$ui_color_hint"
  fi

  _ui_summary_row "$symbol" "$symbol_color" "$label" "$status"
}
