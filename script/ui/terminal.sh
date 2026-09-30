#!/usr/bin/env bash

# Returns success only when stdin and stdout are interactive terminals.
ui_is_interactive() {
  [[ -t 0 && -t 1 ]]
}

# Shared widget support: direct identifiers only; __ui_ belongs to UI internals.
_ui_valid_name() {
  [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ && "$1" != __ui_* ]] || return 2
  local __ui_name_declaration
  __ui_name_declaration="$(declare -p "$1" 2>/dev/null)" || return 0
  [[ ! "$__ui_name_declaration" =~ ^declare\ -[^[:space:]]*n ]] || return 2
}

# Refuse readonly outputs before a renderer can change terminal state.
_ui_output_name() {
  _ui_valid_name "$1" || return
  local __ui_output_declaration
  __ui_output_declaration="$(declare -p "$1" 2>/dev/null)" || return 0
  [[ ! "$__ui_output_declaration" =~ ^declare\ -[^[:space:]]*[rA] ]] || return 2
}

# Verifies an existing indexed (a) or associative (A) array, without aliases.
_ui_array_type() {
  local __ui_array_declaration
  __ui_array_declaration="$(declare -p "$1" 2>/dev/null)" || return 2
  [[ ! "$__ui_array_declaration" =~ ^declare\ -[^[:space:]]*n ]] || return 2
  [[ "$__ui_array_declaration" =~ ^declare\ -[^[:space:]]*$2 ]] || return 2
}

# Returns a normalized event; widgets own navigation and redraw policy.
_ui_read_key() {
  local __ui_key_value='' __ui_key_sequence=''
  IFS= read -rsn1 __ui_key_value || return 130
  case "$__ui_key_value" in
    '') __ui_key_value=enter ;;
    ' ') __ui_key_value=space ;;
    $'\033')
      __ui_key_value=unknown
      if IFS= read -rsn2 -t 0.2 __ui_key_sequence; then
        case "$__ui_key_sequence" in
          '[A'|'OA') __ui_key_value=up ;;
          '[B'|'OB') __ui_key_value=down ;;
          '[C'|'OC') __ui_key_value=right ;;
          '[D'|'OD') __ui_key_value=left ;;
        esac
      fi
      ;;
    *) __ui_key_value=unknown ;;
  esac
  printf -v "$1" '%s' "$__ui_key_value"
}

# Truncates by Bash character length; padding and available width are caller-owned.
_ui_truncate() {
  local __ui_truncate_text="$2" __ui_truncate_limit="$3"
  if ((__ui_truncate_limit <= 0)); then
    __ui_truncate_text=''
  elif ((${#__ui_truncate_text} > __ui_truncate_limit)); then
    __ui_truncate_text="${__ui_truncate_text:0:__ui_truncate_limit-1}…"
  fi
  printf -v "$1" '%s' "$__ui_truncate_text"
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
  _ui_output_name "$1" || return
  local __ui_detail_result_name="$1"
  local __ui_detail_description="$2"
  shift 2

  local __ui_detail_rendered_detail="$__ui_detail_description"
  local __ui_detail_packages=""
  local __ui_detail_package

  for __ui_detail_package in "$@"; do
    __ui_detail_packages+="${__ui_detail_packages:+, }${__ui_detail_package}"
  done

  if [[ -n "$__ui_detail_packages" ]]; then
    __ui_detail_rendered_detail+=$'\n'
    __ui_detail_rendered_detail+="  ${__ui_detail_packages}"
  fi

  printf -v "$__ui_detail_result_name" '%s' "$__ui_detail_rendered_detail"
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
