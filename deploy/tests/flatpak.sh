#!/usr/bin/env bash
set -Eeuo pipefail
script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"
[[ "$(WSL_DISTRO_NAME=Debian _flatpak_installation_scope)" == --user ]]
[[ "$(WSL_INTEROP=/run/WSL/interop _flatpak_installation_scope)" == --user ]]
test_scope=--system
_flatpak_installation_scope() { printf '%s' "$test_scope"; }

# Every system-changing command is replaced. Queries use tab-separated CLI data.
events=()
available=0
remote_rows=''
failure=''
status_report() { events+=("$1"); }
error_report() { events+=("$1"); }
executor_require() {
  events+=("require $1")
  [[ "$1" != flatpak ]] || ((available))
}
command() {
  if [[ "$*" == '-v flatpak' ]]; then ((available)); else builtin command "$@"; fi
}
executor_run() {
  events+=("$*")
  [[ "$*" != "$failure" ]] || return 7
}
executor_run_as_root() { executor_run "root" "$@"; }
executor_retry_as_root() {
  shift 2
  executor_run_as_root "$@" || return
  if [[ "$*" == *'install -y flatpak' || "$*" == *'--noconfirm flatpak' ]]; then available=1; fi
}
flatpak() {
  if [[ "$*" == "list $test_scope --app --columns=application" ]]; then
    printf '%s\n' "${installed_rows:-}"
    return "${installed_status:-0}"
  fi
  [[ "$*" == "remotes $test_scope --show-disabled --columns=name,url,filter,options" ]]
  [[ "${query_status:-0}" == 0 ]] || return "$query_status"
  printf '%s\n' "$remote_rows"
}

# Installed applications are matched by ID, in catalog order, with failures
# and missing Flatpak handled before the questionnaire opens.
available=1 installed_rows=$'md.obsidian.Obsidian\norg.telegram.desktop\norg.telegram.desktop\nunrelated'
installed=(stale)
workflow_installed_packages installed flatpak_apps org.telegram.desktop com.discordapp.Discord md.obsidian.Obsidian
[[ "${installed[*]}" == 'org.telegram.desktop md.obsidian.Obsidian' ]]
installed_status=7 installed=(stale) actual=0
workflow_installed_packages installed flatpak_apps org.telegram.desktop || actual=$?
[[ "$actual" == 7 && "${#installed[@]}" == 0 ]]
installed_status=0 available=0 installed=(stale)
workflow_installed_packages installed flatpak_apps org.telegram.desktop
[[ "${#installed[@]}" == 0 ]]
(
  available=1 installed_rows=$'org.telegram.desktop\nmd.obsidian.Obsidian'
  ui_multiselect_grouped() {
    local -n chosen_ref="$1" preset_ref="$6"
    [[ "${preset_ref[*]}" == 'org.telegram.desktop md.obsidian.Obsidian' ]]
    chosen_ref=("${preset_ref[@]}")
  }
  _questionnaire_read_selectable_packages flatpak_apps fedora 1 1
  workflow_selected_packages chosen flatpak_apps
  [[ "${chosen[*]}" == 'org.telegram.desktop md.obsidian.Obsidian' ]]
)
workflow_select_packages flatpak_apps org.telegram.desktop md.obsidian.Obsidian

for platform in arch debian fedora; do
  available=0 events=() remote_rows=''
  action_prepare_flatpak "$platform" ''
  case "$platform" in
    arch) expected='require pacman root pacman -Syu --needed --noconfirm flatpak' ;;
    debian) expected='require apt root apt update root apt install -y flatpak' ;;
    fedora) expected='require dnf root dnf config-manager setopt fedora-cisco-openh264.enabled=0 root dnf install -y flatpak' ;;
  esac
  [[ "${events[*]}" == "$expected require flatpak status.flatpak_installed root flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo" ]]
done

# Enabled, disabled, filtered, redirected, and missing remote_rows are distinct.
available=1
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tsystem'
events=()
action_prepare_flatpak debian ''
[[ "${#events[@]}" == 0 ]]
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tdisabled'
events=()
action_prepare_flatpak arch ''
[[ "${events[*]}" == 'root flatpak remote-modify --system --enable flathub' ]]
for remote_rows in \
  $'flathub\thttps://example.org/repo/\t\tsystem\nfedora\thttps://example.org/fedora\t\tsystem' \
  $'flathub\thttps://dl.flathub.org/repo/\t/etc/flatpak/filter\tsystem\nfedora\thttps://example.org/fedora\t\tsystem'; do
  events=() actual=0
  action_prepare_flatpak fedora '' || actual=$?
  [[ "$actual" == 1 && "${events[*]}" == error.flathub_configuration ]]
done

# Fedora system remote removal preserves installed refs.
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tuser\nfedora\thttps://example.org/fedora\t\tuser'
events=()
action_prepare_flatpak fedora ''
[[ "${events[*]}" == 'root flatpak remote-delete --system --force fedora' ]]

# Setup failures never reach installation or delete the Fedora remote.
failure='root flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo'
remote_rows=''
events=() actual=0
action_prepare_flatpak fedora '' || actual=$?
[[ "$actual" == 7 && "${#events[@]}" == 1 ]]
available=0 failure='root apt update' events=() actual=0
action_prepare_flatpak debian '' || actual=$?
[[ "$actual" == 7 && "${events[*]}" == 'require apt root apt update' ]]
failure='' available=1

# Query and enable failures retain their status.
query_status=9 events=() actual=0
action_prepare_flatpak fedora '' || actual=$?
[[ "$actual" == 9 && "${#events[@]}" == 0 ]]
query_status=0
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tdisabled\nfedora\thttps://example.org/fedora\t\tsystem'
failure='root flatpak remote-modify --system --enable flathub' events=() actual=0
action_prepare_flatpak fedora '' || actual=$?
[[ "$actual" == 7 && "${#events[@]}" == 1 ]]
failure=''

# Installation preserves terminal prompts for each selected ID and stops on error.
events=()
action_install_flatpak_apps fedora ''
[[ "${events[*]}" == 'flatpak install --system flathub org.telegram.desktop flatpak install --system flathub md.obsidian.Obsidian' ]]
failure='flatpak install --system flathub org.telegram.desktop' events=() actual=0
action_install_flatpak_apps fedora '' || actual=$?
[[ "$actual" == 7 && "${#events[@]}" == 1 ]]
test_scope=--user
# All hosts prepare user remotes and install without root or system-helper.
events=() remote_rows='' failure=''
action_prepare_flatpak debian ''
[[ "${events[*]}" == 'flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' ]]
events=()
action_install_flatpak_apps debian ''
[[ "${events[*]}" == 'flatpak install --user flathub org.telegram.desktop flatpak install --user flathub md.obsidian.Obsidian' ]]
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tdisabled\nfedora\thttps://example.org/fedora\t\tsystem'
events=()
action_prepare_flatpak fedora ''
[[ "${events[*]}" == 'flatpak remote-modify --user --enable flathub' ]]
test_scope=--system
workflow_select_packages flatpak_apps
available=0 events=()
action_prepare_flatpak fedora ''
action_install_flatpak_apps fedora ''
[[ "${#events[@]}" == 0 ]]
catalog_finish_handler finish_handler flatpak_apps
[[ "$finish_handler" == action_install_flatpak_apps ]]

# Real catalog, menu and workflow hand IDs to the installer despite aliases.
(
  menu_output="$(mktemp)"
  trap 'rm -f -- "$menu_output"' EXIT
  _questionnaire_read_selectable_packages flatpak_apps fedora 1 1 \
    <<< $' \n' >"$menu_output"
  grep -Fq Telegram "$menu_output"
  if grep -Fq org.telegram.desktop "$menu_output"; then exit 1; fi
  chosen=()
  workflow_selected_packages chosen flatpak_apps
  [[ "${chosen[*]}" == 'org.telegram.desktop org.qbittorrent.qBittorrent com.mattermost.Desktop org.mozilla.firefox com.discordapp.Discord com.google.Chrome' ]]
  events=() failure=''
  action_install_flatpak_apps fedora ''
  [[ "${events[*]}" == 'flatpak install --system flathub org.telegram.desktop flatpak install --system flathub org.qbittorrent.qBittorrent flatpak install --system flathub com.mattermost.Desktop flatpak install --system flathub org.mozilla.firefox flatpak install --system flathub com.discordapp.Discord flatpak install --system flathub com.google.Chrome' ]]
)

printf 'Flatpak procedure validation passed.\n'
