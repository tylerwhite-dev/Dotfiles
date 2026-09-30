#!/usr/bin/env bash

# Checks the commands needed by the direct-input developer tools phase.
action_prepare_macos_command_line_tools() {
  executor_require xcode-select || return
  executor_require xcrun
}

# Leaves a working CLT or Xcode selection intact; verifies GUI installation.
action_install_macos_command_line_tools() {
  local response
  if executor_macos_developer_tools_ready; then
    status_report status.macos_clt_ready
    return 0
  fi

  executor_run xcode-select --install || return
  status_report status.macos_clt_wait
  if ! IFS= read -r response; then
    error_report error.macos_clt_wait_interrupted
    return 130
  fi
  if ! executor_macos_developer_tools_ready; then
    error_report error.macos_clt_missing
    return 1
  fi
  status_report status.macos_clt_ready
}
