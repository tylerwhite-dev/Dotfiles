#!/usr/bin/env bash
message_define error.interactive_required \
  "An interactive terminal is required."
message_define error.config_invalid \
  "Could not load the setup configuration."
message_define error.distribution_unsupported \
  $'The system could not be detected or is not supported.\nSupported systems: Arch Linux, Debian, Ubuntu, Fedora, and macOS.'
message_define error.unknown_flag \
  "Unknown flag: %s"
message_define error.dry_run_removed \
  "SETUP_DRY_RUN is no longer supported. Unset it before running setup."
message_define error.root_execution \
  "Run this setup as a regular user. It will request sudo when needed."
message_define error.command_missing \
  "Required command not found: %s"
message_define error.input_interrupted \
  "Input was interrupted. No changes were applied."
message_define error.homebrew_missing \
  "Homebrew was not installed at %s"
message_define error.native_packages_unsupported \
  "Native package installation is not implemented for: %s"
message_define error.brew_not_installed \
  "Homebrew is required for the selected packages but was not installed."
message_define error.flags_conflict \
  "Conflicting flags: --yolo and --add-optionals cannot be used together."
message_define error.macos_clt_missing \
  "Apple developer tools are not ready. Complete the Command Line Tools installation or select a working Xcode, then run setup again."
message_define status.distribution_detected \
  "Detected system: %s"
message_define status.settings_confirmed \
  "Settings confirmed."
message_define status.yolo_mode \
  "YOLO mode enabled: every procedure without a package selection runs without confirmation."
message_define status.yolo_skipped_optionals \
  "Skipped optional procedures: %s. Choose their packages in an interactive run."
message_define status.exited \
  "Exited without changes."
message_define status.no_selection \
  "No procedures were selected. Nothing to do."
message_define status.optionals_none \
  "No optional packages were selected. Nothing to do."
message_define status.optionals_brew_prepare \
  "Execution will prepare Homebrew for the selected packages; on macOS it will also check Apple Command Line Tools."
message_define status.selected_count \
  "%d selected"
message_define status.all_packages_selected \
  "all"
message_define status.no_packages_selected \
  "no packages selected"
message_define status.setup_complete \
  "Setup completed successfully."
message_define status.sudo_auth_prompt \
  "Administrator access for %s. Enter your sudo password if prompted."
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
message_define package_category_other "Other"
message_define ui.multiselect.all_label "All"
# Escaped conversions survive message_format for the widget's four counters.
message_define ui.multiselect.status_format "cols %%d-%%d/%%d  ·  %%d selected"
message_define ui.multiselect.navigation_hint "↑↓ move  ←→ column  Space toggle  Enter confirm"
message_define ui.multiselect.resize_notice "Increase terminal size, then press a key."
message_define prompt.action "Choose an action:"
message_define prompt.brew_install "Homebrew is not installed. Install it?"
message_define flags.help $'Usage: %s [flags]\n\nFlags:\n  -y, --yolo             Run every procedure that needs no package selection.\n  -a, --add-optionals    Select optional Homebrew and Linux Flatpak or macOS cask packages.\n  -h, --help             Show this help message.\n\nNote: --yolo skips optional package sets, Flatpak apps and casks,\nand it cannot be combined with --add-optionals.'
