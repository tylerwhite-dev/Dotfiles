#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

ansible-galaxy collection install \
  --requirements-file "${repo_dir}/ansible/requirements.yml"

exec ansible-playbook \
  "${repo_dir}/ansible/desktop.yml" \
  --inventory "${repo_dir}/ansible/inventory.yml" \
  --ask-become-pass \
  "$@"
