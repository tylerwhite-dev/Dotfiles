#!/usr/bin/env bash

# Runs selected procedure handlers in catalog order.
runner_run() {
  local platform="$1"
  local distribution_name="$2"
  local repository_dir="$3"
  local title
  local metadata
  local completion_message
  local procedure_id
  local handler
  local finish_handler
  local label
  local requires_root
  local current=0
  local -a selected=()

  if ((EUID == 0)); then
    error_report error.root_execution
    return 1
  fi

  workflow_selected selected "$platform"
  if ((${#selected[@]} == 0)); then
    message_format completion_message status.no_selection
    ui_success "$completion_message"
    return 0
  fi

  message_format title stage.execution.title
  message_format metadata stage.execution.meta \
    "$distribution_name" "${#selected[@]}"
  ui_stage "$title" "$metadata"

  for procedure_id in "${selected[@]}"; do
    ((current += 1))
    catalog_handler handler "$procedure_id"
    catalog_finish_handler finish_handler "$procedure_id"
    catalog_requires_root requires_root "$procedure_id" "$platform"
    message_format label "procedure.${procedure_id}.label"

    process_run \
      "$handler" "$current" "${#selected[@]}" "$label" \
      "$requires_root" "$platform" "$repository_dir" "$finish_handler" || return
  done

  message_format completion_message status.setup_complete

  ui_success "$completion_message"
}
