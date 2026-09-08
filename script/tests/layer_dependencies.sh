#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Fails the test when a forbidden dependency pattern appears in a path.
assert_no_match() {
  local description="$1"
  local pattern="$2"
  shift 2

  local matches
  if matches="$(grep -REn "$pattern" "$@")"; then
    printf 'Layer dependency test failed: %s\n%s\n' \
      "$description" "$matches" >&2
    return 1
  fi
}

assert_no_match \
  "actions must not render UI or format messages" \
  'ui_|message_(define|format)' \
  "${script_root}/logic/actions"

assert_no_match \
  "UI must not know about configuration or business modules" \
  'catalog_|workflow_|executor_|action_|procedure_|package_group|message_' \
  "${script_root}/ui"

assert_no_match \
  "configuration must not render UI or execute commands" \
  'ui_|executor_|workflow_' \
  "${script_root}/config"

printf 'Layer dependency validation passed.\n'
