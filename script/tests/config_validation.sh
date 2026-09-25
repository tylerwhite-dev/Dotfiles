#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../logic/load.sh
source "${script_root}/logic/load.sh"

validation_error="$(mktemp)"
trap 'rm -f -- "$validation_error"' EXIT

catalog_validate

# Grouped rows and the flat package list must stay in agreement: every item row
# is exactly one package of the flat list, in the same order.
rows=()
kinds=()
catalog_package_rows rows kinds homebrew_extended macos brew
[[ "${rows[*]}" == 'Dev tools go nvm rustup uv sdkman-cli Terminal tmux yazi mailsy taproom Monitoring lazydocker nvtop tio Media yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full' ]]
[[ "${kinds[*]}" == 'g i i i i i g i i i i g i i i g i i i i i' ]]

flat=()
items=()
for ((index = 0; index < ${#rows[@]}; index++)); do
  if [[ "${kinds[index]}" == "i" ]]; then
    items+=("${rows[index]}")
  fi
done
catalog_packages flat homebrew_extended macos brew
[[ "${#items[@]}" -eq "${#flat[@]}" ]]
[[ "${items[*]}" == "${flat[*]}" ]]

# A procedure without category references renders a plain item list.
plain_rows=()
plain_kinds=()
catalog_package_rows plain_rows plain_kinds homebrew macos brew
((${#plain_kinds[@]} == ${#plain_rows[@]}))
for kind in "${plain_kinds[@]}"; do
  [[ "$kind" == "i" ]]
done

# Loose group references mixed with a category are appended under the fallback
# group, and the flat list still matches the item rows. A subshell keeps these
# declarations out of the shared catalog.
(
  package_group mix_source loose alpha beta
  package_group mix_source grouped gamma
  package_category mix_source mixed "Mixed" grouped
  procedure_define mix_procedure
  procedure_handler mix_procedure action_install_native_packages
  procedure_platforms mix_procedure macos
  procedure_packages mix_procedure mix_source mixed
  procedure_packages mix_procedure mix_source loose
  message_define procedure.mix_procedure.question "Mix?"
  message_define procedure.mix_procedure.label "Mix"
  message_define procedure.mix_procedure.description "Mix"
  catalog_validate

  mixed_rows=()
  mixed_kinds=()
  catalog_package_rows mixed_rows mixed_kinds mix_procedure macos
  [[ "${mixed_rows[*]}" == 'Mixed gamma Other alpha beta' ]]
  [[ "${mixed_kinds[*]}" == 'g i g i i' ]]

  mixed_flat=()
  catalog_packages mixed_flat mix_procedure macos mix_source
  [[ "${mixed_flat[*]}" == 'gamma alpha beta' ]]
)

# Declaration errors are rejected instead of silently producing broken rows.
(
  if package_category neg_source empty_label "Label" 2>"$validation_error"; then
    exit 1
  fi
  grep -Fq 'needs at least one package group' "$validation_error"
)
(
  package_group neg_source present alpha
  if package_category neg_source no_label "" present 2>"$validation_error"; then
    exit 1
  fi
  grep -Fq 'needs a label' "$validation_error"
)
(
  package_group neg_source present alpha
  if package_category neg_source missing_member "Missing" absent 2>"$validation_error"; then
    exit 1
  fi
  grep -Fq 'references an unknown package group: neg_source:absent' "$validation_error"
)
(
  package_group neg_source blank ""
  if package_category neg_source empty_member "Empty" blank 2>"$validation_error"; then
    exit 1
  fi
  grep -Fq 'references an empty package group: neg_source:blank' "$validation_error"
)
(
  if package_group neg_source twice alpha 2>"$validation_error" &&
    package_group neg_source twice beta 2>"$validation_error"; then
    exit 1
  fi
  grep -Fq 'declared more than once: neg_source:twice' "$validation_error"
)
(
  package_group neg_source present alpha
  package_category neg_source shared "Shared" present
  if package_group neg_source shared beta 2>"$validation_error"; then
    exit 1
  fi
  grep -Fq 'group name is already used by a category: neg_source:shared' "$validation_error"
)

printf 'Configuration validation passed.\n'
