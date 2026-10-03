#!/usr/bin/env bash

package_group flatpak internet \
  org.telegram.desktop org.qbittorrent.qBittorrent com.mattermost.Desktop
package_group flatpak work_media \
  md.obsidian.Obsidian com.bitwarden.desktop org.videolan.VLC \
  io.bassi.Amberol org.gnome.Snapshot com.github.johnfactotum.Foliate \
  app.drey.EarTag org.inkscape.Inkscape org.gnome.Decibels org.gnome.Loupe
package_group flatpak development \
  ai.lmstudio.lm-studio com.jgraph.drawio.desktop me.iepure.devtoolbox
package_group flatpak system \
  com.belmoussaoui.Authenticator it.mijorus.gearlever \
  com.mattjakeman.ExtensionManager com.github.tchx84.Flatseal

package_category flatpak internet_apps "Internet" internet
package_category flatpak work_apps "Work & Media" work_media
package_category flatpak developer_apps "Dev tools" development
package_category flatpak system_apps "System" system

message_define error.flathub_configuration \
  "The system flathub remote has an unexpected URL or a filter. Review its configuration before running setup again."

message_define status.flatpak_installed \
  "Flatpak is installed. Log out and back in after setup if applications do not appear in the desktop menu."

message_define status.flatpak_fedora_remove \
  "Removing the system fedora Flatpak remote. Installed applications and runtimes remain, but can no longer receive updates from this remote."

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
      executor_run_as_root \
        dnf config-manager setopt fedora-cisco-openh264.enabled=0 || return
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

procedure_define flatpak_apps
procedure_handler flatpak_apps action_prepare_flatpak
procedure_finish_handler flatpak_apps action_install_flatpak_apps
procedure_platforms flatpak_apps arch debian fedora
procedure_requires_root flatpak_apps arch debian fedora
procedure_selectable flatpak_apps
procedure_packages flatpak_apps \
  flatpak internet_apps \
  flatpak work_apps \
  flatpak developer_apps \
  flatpak system_apps
message_define procedure.flatpak_apps.question \
  "Select Linux applications to install with Flatpak?"
message_define procedure.flatpak_apps.label "Install selected Flatpak applications"
message_define procedure.flatpak_apps.description \
  "Install Flatpak if missing, configure system Flathub, and install selected applications. On Fedora, remove the system fedora remote while retaining installed applications."
