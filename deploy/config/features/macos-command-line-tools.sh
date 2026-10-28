#!/usr/bin/env bash

message_define error.macos_clt_wait_interrupted \
  "Waiting for Apple developer tools was interrupted. The system installer may still be running."

message_define status.macos_clt_ready "Apple developer tools are ready."

message_define status.macos_clt_wait \
  "Complete the Command Line Tools installation in Apple's dialog, then press Enter to verify."

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

procedure_define macos_command_line_tools
procedure_handler macos_command_line_tools action_prepare_macos_command_line_tools
procedure_finish_handler macos_command_line_tools action_install_macos_command_line_tools
procedure_platforms macos_command_line_tools macos
message_define procedure.macos_command_line_tools.question "Check and install Apple Command Line Tools?"
message_define procedure.macos_command_line_tools.label "Check and install Apple Command Line Tools"
message_define procedure.macos_command_line_tools.description \
  "A working CLT or Xcode selection is preserved. If needed, complete Apple's installation dialog, then press Enter to verify."
