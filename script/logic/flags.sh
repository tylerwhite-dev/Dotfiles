#!/usr/bin/env bash

# Prints the CLI usage help text and exits successfully.
_flags_show_help() {
  local help_text
  message_format help_text flags.help \
    "${SETUP_SCRIPT_ROOT}/dotfiles-deploy.sh"
  ui_notice "$help_text"
  exit 0
}

# Prints an error for an unknown flag and exits with status 2.
_flags_unknown() {
  error_report error.unknown_flag "$1"
  exit 2
}

# Parses CLI flags and records them for downstream modules to consume.
flags_parse() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      --yolo)
        SETUP_YOLO=1
        ;;
      --dry-run)
        SETUP_DRY_RUN=1
        ;;
      --help | -h)
        _flags_show_help
        ;;
      *)
        _flags_unknown "$arg"
        ;;
    esac
  done
}
