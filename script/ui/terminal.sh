#!/usr/bin/env bash

# Returns success only when stdin and stdout are interactive terminals.
ui_is_interactive() {
  [[ -t 0 && -t 1 ]]
}

# Prints a successful status message using the success color.
ui_success() {
  printf '\n%s%s%s\n' "$ui_color_success" "$1" "$ui_color_reset"
}

# Prints a success-colored line without adding a leading blank line.
ui_success_line() {
  printf '%s%s%s\n' "$ui_color_success" "$1" "$ui_color_reset"
}

# Prints a heading-colored line without adding a leading blank line.
ui_heading_line() {
  printf '%s%s%s\n' "$ui_color_heading" "$1" "$ui_color_reset"
}

# Prints an error message using the error color and stderr.
ui_error() {
  printf '\n%s%s%s\n' "$ui_color_error" "$1" "$ui_color_reset" >&2
}

# Prints an unstyled notice line.
ui_notice() {
  printf '%s\n' "$1"
}

# Keeps ANSI palette rendering disabled when terminal colors are unavailable.
ui_ansi_palette() {
  if [[ -z "$ui_color_reset" ]]; then
    return 0
  fi

  # printf '\033[0;30m██\033[0;31m██\033[0;32m██\033[0;33m██\033[0;34m██\033[0;35m██\033[0;36m██\033[0;37m██\033[0m\n'
  # printf '\033[1;30m██\033[1;31m██\033[1;32m██\033[1;33m██\033[1;34m██\033[1;35m██\033[1;36m██\033[1;37m██\033[0m\n'
}

# Prints a command in a shell-escaped, easy-to-read form.
ui_command() {
  local argument

  printf '  +'
  for argument in "$@"; do
    printf ' %q' "$argument"
  done
  printf '\n'
}

# Builds a description and optional comma-separated package line.
ui_detail() {
  local result_name="$1"
  local description="$2"
  shift 2

  local rendered_detail="$description"
  local packages=""
  local package

  for package in "$@"; do
    packages+="${packages:+, }${package}"
  done

  if [[ -n "$packages" ]]; then
    rendered_detail+=$'\n'
    rendered_detail+="  ${packages}"
  fi

  printf -v "$result_name" '%s' "$rendered_detail"
}

# Prints each detail line with the package/comment color and two-space indent.
_ui_print_detail() {
  local detail="$1"
  local line
  local rendered_line

  while IFS= read -r line; do
    if [[ "$line" == "  "* ]]; then
      rendered_line="$line"
    else
      rendered_line="  ${line}"
    fi
    printf '%s%s%s\n' "$ui_color_package" "$rendered_line" "$ui_color_reset"
  done <<< "$detail"
}
