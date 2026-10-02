#!/usr/bin/env bash

# Installs the CLI only when absent, independently of the base package choice.
action_install_flatpak_binary() {
  local platform="$1"
  if command -v flatpak >/dev/null 2>&1; then
    return 0
  fi
  case "$platform" in
    arch)
      executor_require pacman || return
      executor_retry_as_root "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        pacman -Syu --needed --noconfirm flatpak || return
      ;;
    debian)
      executor_require apt || return
      executor_retry_as_root "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        apt update || return
      executor_retry_as_root "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        apt install -y flatpak || return
      ;;
    fedora)
      executor_require dnf || return
      executor_retry_as_root "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
        dnf install -y flatpak || return
      ;;
    *) error_report error.native_packages_unsupported "$platform"; return 1 ;;
  esac
  executor_require flatpak || return
  status_report status.flatpak_installed
}

# Validates existing configuration before modifying remotes. Tab-separated
# fields are parsed without IFS splitting, which would discard an empty filter.
action_prepare_flatpak() {
  local platform="$1" remotes line name url filter options fields
  local flathub_found=0 fedora_found=0
  local -a selected=()
  workflow_selected_packages selected flatpak_apps || return
  ((${#selected[@]} > 0)) || return 0
  action_install_flatpak_binary "$platform" || return
  remotes="$(LC_ALL=C flatpak remotes --system --show-disabled \
    --columns=name,url,filter,options)" || return
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    name="${line%%$'\t'*}"
    if [[ "$name" == fedora ]]; then fedora_found=1; fi
    [[ "$name" == flathub ]] || continue
    flathub_found=1
    fields="${line#*$'\t'}"
    url="${fields%%$'\t'*}"
    fields="${fields#*$'\t'}"
    filter="${fields%%$'\t'*}"
    options="${fields#*$'\t'}"
    case "${url%/}" in
      https://dl.flathub.org/repo) ;;
      *) error_report error.flathub_configuration; return 1 ;;
    esac
    if [[ -n "$filter" && "$filter" != - ]]; then
      error_report error.flathub_configuration
      return 1
    fi
    if [[ ",${options//;/,}," == *,disabled,* ]]; then
      executor_run_as_root flatpak remote-modify --system --enable flathub || return
    fi
  done <<< "$remotes"
  if ((flathub_found == 0)); then
    executor_run_as_root flatpak remote-add --system --if-not-exists \
      flathub https://dl.flathub.org/repo/flathub.flatpakrepo || return
  fi
  if [[ "$platform" == fedora ]] && ((fedora_found)); then
    status_report status.flatpak_fedora_remove
    executor_run_as_root flatpak remote-delete --system --force fedora || return
  fi
}

# Accepts installation confirmations while retaining terminal authentication.
action_install_flatpak_apps() {
  local package
  local -a selected=()
  workflow_selected_packages selected flatpak_apps || return
  ((${#selected[@]} > 0)) || return 0
  for package in "${selected[@]}"; do
    executor_run flatpak install -y "$package" || return
  done
}
