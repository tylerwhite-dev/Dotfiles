#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"
unset SETUP_DRY_RUN

check_parse() {
  local expected_status="$1" expected_output="$2" output status=0
  shift 2
  output="$(
    (
      flags_parse "$@" || exit $?
      printf 'parsed:%s' "$SETUP_MODE"
    ) 2>&1
  )" || status=$?
  if [[ "$status" != "$expected_status" || "$output" != *"$expected_output"* ]]; then
    printf 'Unexpected parse result for [%s]: status=%s output=%s\n' "$*" "$status" "$output" >&2
    exit 1
  fi
}

# Existing environment values must not choose a mode or leak between parses.
SETUP_MODE=server
check_parse 0 parsed:standard
for mode in server desktop wsl mac; do check_parse 0 "parsed:$mode" "--$mode"; done
for flag in -a --add-optionals; do check_parse 0 parsed:optionals "$flag"; done
for flag in -h --help; do
  check_parse 0 "Usage: ${SETUP_REPOSITORY_ROOT}/dotfiles-deploy.sh [flag]" "$flag"
done
for flag in -y --yolo --unknown -ya -- ''; do check_parse 2 'Unknown flag:' "$flag"; done

# Every pair is invalid, even aliases, repetitions and help in either position.
flags=(--server --desktop --wsl --mac -a --add-optionals -h --help --unknown)
for first in "${flags[@]}"; do
  for second in "${flags[@]}"; do
    check_parse 2 'Only one flag is allowed per run.' "$first" "$second"
  done
done
check_parse 2 'Only one flag is allowed per run.' -y -a -h

flags_parse --server
flags_parse --add-optionals
[[ "$SETUP_MODE" == optionals ]]
flags_parse
[[ "$SETUP_MODE" == standard ]]
SETUP_DRY_RUN=0
check_parse 2 'SETUP_DRY_RUN is no longer supported.'

printf 'CLI flag validation passed.\n'
