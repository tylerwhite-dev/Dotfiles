#!/usr/bin/env bash

# Formats an error key and sends the result to the UI error renderer.
error_report() {
  local key="$1"
  shift

  local text
  if message_format text "$key" "$@"; then
    ui_error "$text"
  else
    ui_error "$key"
  fi
}

# Formats a status key and sends the result to the UI notice renderer.
status_report() {
  local key="$1"
  shift

  local text
  if message_format text "$key" "$@"; then
    ui_notice "$text"
  else
    ui_notice "$key"
  fi
}
