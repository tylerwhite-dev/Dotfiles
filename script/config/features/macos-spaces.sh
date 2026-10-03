#!/usr/bin/env bash

# Keeps the existing Spaces order without changing other Dock preferences.
action_configure_macos_spaces() {
  executor_require defaults || return
  executor_run defaults write com.apple.dock mru-spaces -bool false || return
  executor_restart_macos_app Dock
}

procedure_define macos_spaces
procedure_handler macos_spaces action_configure_macos_spaces
procedure_platforms macos_spaces macos
message_define procedure.macos_spaces.question "Disable automatic rearrangement of Spaces?"
message_define procedure.macos_spaces.label "Keep Spaces in their existing order"
message_define procedure.macos_spaces.description \
  "Disable rearrangement by most recent use. Other Dock settings are unchanged. Dock will restart."
