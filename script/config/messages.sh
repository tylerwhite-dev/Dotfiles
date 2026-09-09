#!/usr/bin/env bash

message_define error.interactive_required \
  "An interactive terminal is required."
message_define error.config_invalid \
  "Could not load the setup configuration."
message_define error.distribution_unsupported \
  $'The distribution could not be detected or is not supported.\nSupported distributions: Arch Linux, Debian, Ubuntu, and Fedora.'
message_define error.dry_run_invalid \
  "SETUP_DRY_RUN must be 0 or 1."
message_define error.unknown_flag \
  "Unknown flag: %s"
message_define error.root_execution \
  "Run this setup as a regular user. It will request sudo when needed."
message_define error.command_missing \
  "Required command not found: %s"
message_define error.input_interrupted \
  "Input was interrupted. No changes were applied."
message_define error.repository_marker_missing \
  "Repository marker not found: %s"
message_define error.homebrew_missing \
  "Homebrew was not installed at %s"
message_define error.native_packages_unsupported \
  "Native package installation is not implemented for: %s"
message_define error.current_user_unknown \
  "Could not determine the current user."
message_define error.zsh_missing \
  "Zsh is not installed at /bin/zsh."
message_define error.home_unknown \
  "Could not determine the user's home directory."
message_define error.yay_missing \
  "The yay build completed, but yay was not found in PATH."

message_define status.distribution_detected \
  "Detected distribution: %s"
message_define status.settings_confirmed \
  "Settings confirmed."
message_define status.yolo_mode \
  "YOLO mode enabled: all procedures will be executed without confirmation."
message_define status.exited \
  "Exited without changes."
message_define status.no_selection \
  "No procedures were selected. Nothing to do."
message_define status.dry_run_complete \
  "Dry run completed. No changes were made."
message_define status.setup_complete \
  "Setup completed successfully."
message_define status.yay_installed \
  "yay is already installed."
message_define status.retry \
  "Command failed. Retrying in %s seconds (%s/%s)."
message_define status.elapsed.minutes \
  "Completed in %dm %02ds."
message_define status.elapsed.seconds \
  "Completed in %ds."

message_define stage.questionnaire.title "SYSTEM SETUP"
message_define stage.questionnaire.meta "%s · %d procedures available"
message_define stage.review.title "REVIEW SELECTION"
message_define stage.review.meta "%s · selected setup procedures"
message_define stage.execution.title "START RUN"
message_define stage.execution.meta "%s · %d procedures selected"
message_define question.progress "◉  %02d / %02d  %s"

message_define option.yes "Yes"
message_define option.no "No"
message_define option.start "Start execution"
message_define option.restart "Restart questionnaire"
message_define option.exit "Exit without changes"
message_define label.yes "yes"
message_define label.no "no"
message_define prompt.action "Choose an action:"

message_define flags.help $'Usage: %s [flags]\n\nFlags:\n  --yolo       Execute all procedures without confirmation.\n  --dry-run    Print commands without changing the system.\n  -h, --help   Show this help message.'
