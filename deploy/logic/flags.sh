#!/usr/bin/env bash

# Accepts at most one CLI flag and records the requested mode.
flags_parse() {
  SETUP_MODE=standard
  if (($# > 1)); then
    error_report error.too_many_flags
    return 2
  fi
  if [[ -v SETUP_DRY_RUN ]]; then
    error_report error.dry_run_removed
    return 2
  fi
  (($# == 0)) && return 0

  case "$1" in
    --yolo | -y) SETUP_MODE=yolo ;;
    --add-optionals | -a) SETUP_MODE=optionals ;;
    --help | -h)
      local help_text
      message_format help_text flags.help "${SETUP_REPOSITORY_ROOT}/dotfiles-deploy.sh"
      ui_notice "$help_text"
      exit 0
      ;;
    *) error_report error.unknown_flag "$1"; return 2 ;;
  esac
}
