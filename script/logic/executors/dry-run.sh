#!/usr/bin/env bash

# Pretends to execute a command and always reports success.
_executor_dry_run_run() {
  return 0
}

# Returns a stable path without creating a file during a dry run.
_executor_dry_run_temp_file() {
  printf '/tmp/dotfiles-setup-dry-run'
}
