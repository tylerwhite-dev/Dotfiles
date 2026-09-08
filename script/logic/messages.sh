#!/usr/bin/env bash

declare -Ag _MESSAGE_TEMPLATES=()

# Registers a unique message template by key.
message_define() {
  local key="$1"
  local template="$2"

  if [[ -v "_MESSAGE_TEMPLATES[$key]" ]]; then
    printf 'Message declared more than once: %s\n' "$key" >&2
    return 1
  fi

  _MESSAGE_TEMPLATES["$key"]="$template"
}

# Formats a registered template into the caller-provided variable.
message_format() {
  local result_name="$1"
  local key="$2"
  shift 2

  if [[ ! -v "_MESSAGE_TEMPLATES[$key]" ]]; then
    printf 'Unknown message: %s\n' "$key" >&2
    return 1
  fi

  printf -v "$result_name" "${_MESSAGE_TEMPLATES[$key]}" "$@"
}

# Tests whether a message key is present in the registry.
message_exists() {
  [[ -v "_MESSAGE_TEMPLATES[$1]" ]]
}
