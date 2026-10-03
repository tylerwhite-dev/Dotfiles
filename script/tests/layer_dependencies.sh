#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Fails the test when a forbidden dependency pattern appears in a path.
assert_no_match() {
  local description="$1"
  local pattern="$2"
  shift 2

  local matches
  if matches="$(grep -REn --include='*.sh' "$pattern" "$@")"; then
    printf 'Layer dependency test failed: %s\n%s\n' \
      "$description" "$matches" >&2
    return 1
  fi
}

# Feature files mix declarations and handlers. Check each part separately.
awk '
  FNR == 1 { handler = 0; continuation = 0 }
  /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
  /^[a-zA-Z_][a-zA-Z0-9_]*\(\) \{$/ { handler = 1; next }
  handler && /^\}$/ { handler = 0; next }
  handler {
    if ($0 ~ /ui_|message_(define|format)/) {
      printf "%s:%d: handlers must not render UI or format messages\n", FILENAME, FNR
      failed = 1
    }
    next
  }
  continuation { continuation = ($0 ~ /\\$/); next }
  /^(package_group|package_category|message_define|procedure_define|procedure_handler|procedure_finish_handler|procedure_platforms|procedure_requires|procedure_requires_root|procedure_selectable|procedure_packages)[[:space:]]/ {
    continuation = ($0 ~ /\\$/)
    next
  }
  {
    printf "%s:%d: feature top level must only declare data and handlers\n", FILENAME, FNR
    failed = 1
  }
  END { exit failed }
' "${script_root}"/config/features/*.sh

assert_no_match \
  "UI must not know about configuration or business modules" \
  'catalog_|workflow_|executor_|action_|procedure_|package_group|message_' \
  "${script_root}/ui"

assert_no_match \
  "shared configuration must not render UI or execute commands" \
  'ui_|executor_|workflow_' \
  "${script_root}/config/settings.sh" "${script_root}/config/messages.sh" \
  "${script_root}/config/procedure-order.sh"

assert_no_match \
  "application must not call private action helpers" \
  '(^|[^[:alnum:]_])_action_[[:alnum:]_]+[[:space:]]' \
  "${script_root}/logic/app.sh"

printf 'Layer dependency validation passed.\n'
