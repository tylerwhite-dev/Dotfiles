#!/usr/bin/env bash

# Executes the command exactly as provided by the caller.
_executor_real_run() {
  "$@"
}

# Creates a unique temporary file for real command execution.
_executor_real_temp_file() {
  mktemp "${TMPDIR:-/tmp}/dotfiles-setup.XXXXXX"
}
