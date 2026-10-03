#!/usr/bin/env bash

# Changes only the selected Finder preferences, including Home as its target.
action_configure_macos_finder() {
  executor_require defaults || return
  executor_run defaults write NSGlobalDomain AppleShowAllExtensions -bool true || return
  executor_run defaults write com.apple.finder ShowPathbar -bool true || return
  executor_run defaults write com.apple.finder _FXSortFoldersFirst -bool true || return
  executor_run defaults write com.apple.finder FXDefaultSearchScope -string SCcf || return
  executor_run defaults write com.apple.finder NewWindowTarget -string PfHm || return
  executor_restart_macos_app Finder
}

procedure_define macos_finder
procedure_handler macos_finder action_configure_macos_finder
procedure_platforms macos_finder macos
message_define procedure.macos_finder.question "Configure Finder for projects?"
message_define procedure.macos_finder.label "Configure Finder for projects"
message_define procedure.macos_finder.description \
  "Show extensions and the path bar, keep folders first, search the current folder, and open new windows in Home. The status bar is unchanged. Finder will restart."
