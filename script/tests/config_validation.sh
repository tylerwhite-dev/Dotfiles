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
[[ "${rows[*]}" == 'Dev tools go nvm rustup uv sdkman-cli zig bun cmake ninja tio Terminal lazygit lazyjournal lazydocker nvtop btop macmon taproom tmux zellij yazi mailsy Media yt-dlp ffmpeg ffmpeg-full imagemagick imagemagick-full CLI Harness opencode hermes-agent openclaw' ]]
[[ "${kinds[*]}" == 'g i i i i i i i i i i g i i i i i i i i i i i g i i i i i g i i i' ]]

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

# macOS casks use the same category UI but remain a separate package source.
cask_rows=()
cask_kinds=()
cask_items=()
cask_flat=()
cask_categories=()
catalog_package_rows cask_rows cask_kinds homebrew_casks macos brew_cask
catalog_packages cask_flat homebrew_casks macos brew_cask
for ((index = 0; index < ${#cask_rows[@]}; index++)); do
  if [[ "${cask_kinds[index]}" == i ]]; then
    cask_items+=("${cask_rows[index]}")
  else
    cask_categories+=("${cask_rows[index]}")
  fi
done
[[ "${cask_items[*]}" == "${cask_flat[*]}" ]]
[[ "${#cask_flat[@]}" -eq 29 ]]
[[ "${cask_categories[*]}" == 'Internet Work & Media Dev tools System Games' ]]
[[ "${cask_rows[*]}" == 'Internet firefox google-chrome telegram qbittorrent amneziavpn Work & Media obsidian libreoffice iina bitwarden veracrypt Dev tools android-studio intellij-idea-ce qt-creator vscodium docker-desktop ghostty lm-studio zed System utm appcleaner betterdisplay coconutbattery macfuse mos raycast balenaetcher raspberry-pi-imager Games playcover-community steam' ]]

# A procedure without category references renders a plain item list.
plain_rows=()
plain_kinds=()
catalog_package_rows plain_rows plain_kinds homebrew macos brew
((${#plain_kinds[@]} == ${#plain_rows[@]}))
for kind in "${plain_kinds[@]}"; do
  [[ "$kind" == "i" ]]
done

# Loose groups stay in declaration order under consecutive fallback headings.
# A subshell keeps these
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

  # Leading loose groups, repeated Other headings, duplicates and source filters.
  package_group mix_source extra delta
  package_group other_source unrelated ignored
  package_group native macos native-item
  procedure_define alternating
  procedure_packages alternating \
    mix_source loose mix_source extra mix_source mixed mix_source loose \
    other_source unrelated native @distribution
  alternating_rows=(); alternating_kinds=(); alternating_flat=(); alternating_items=()
  catalog_package_rows alternating_rows alternating_kinds alternating macos
  catalog_packages alternating_flat alternating macos
  [[ "${alternating_rows[*]}" == 'Other alpha beta delta Mixed gamma Other alpha beta ignored native-item' ]]
  [[ "${alternating_kinds[*]}" == 'g i i i g i g i i i i' ]]
  for ((index=0; index<${#alternating_rows[@]}; index++)); do
    [[ "${alternating_kinds[index]}" == i ]] && alternating_items+=("${alternating_rows[index]}")
  done
  [[ "${alternating_items[*]}" == "${alternating_flat[*]}" ]]
  catalog_package_rows alternating_rows alternating_kinds alternating macos other_source
  [[ "${alternating_rows[*]}" == ignored && "${alternating_kinds[*]}" == i ]]
  catalog_package_rows alternating_rows alternating_kinds alternating macos native
  [[ "${alternating_rows[*]}" == native-item && "${alternating_kinds[*]}" == i ]]
  # Output names may match the old implementation's locals.
  group_packages=(); group_keys=()
  catalog_package_rows group_packages group_keys alternating macos mix_source
  catalog_packages key alternating macos mix_source
  [[ "${key[*]}" == 'alpha beta delta gamma alpha beta' ]]
  [[ "${group_packages[*]}" == 'Other alpha beta delta Mixed gamma Other alpha beta' ]]
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
