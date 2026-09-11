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
  local has_yolo=0
  local has_add_optionals=0

  for arg in "$@"; do
    case "$arg" in
      --yolo)
        has_yolo=1
        ;;
      --add-optionals)
        has_add_optionals=1
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

  if (( has_yolo + has_add_optionals > 1 )); then
    error_report error.flags_conflict
    exit 2
  fi

  [[ "$has_yolo" == "1" ]]          && SETUP_YOLO=1
  [[ "$has_add_optionals" == "1" ]] && SETUP_ADD_OPTIONALS=1
  return 0
}
