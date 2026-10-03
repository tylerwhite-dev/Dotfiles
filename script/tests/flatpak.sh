#!/usr/bin/env bash
set -Eeuo pipefail
script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

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
  [[ "$*" == 'remotes --system --show-disabled --columns=name,url,filter,options' ]]
  [[ "${query_status:-0}" == 0 ]] || return "$query_status"
  printf '%s\n' "$remote_rows"
}
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

# Fedora removal preserves installed refs by forcing only remote deletion.
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tsystem\nfedora\thttps://example.org/fedora\t\tdisabled'
events=()
action_prepare_flatpak fedora ''
[[ "${events[*]}" == 'status.flatpak_fedora_remove root flatpak remote-delete --system --force fedora' ]]
events=()
action_prepare_flatpak debian ''
[[ "${#events[@]}" == 0 ]]
remote_rows=$'fedora\thttps://example.org/fedora\t\tsystem'
events=()
action_prepare_flatpak fedora ''
[[ "${events[0]}" == 'root flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' ]]
[[ "${events[-1]}" == 'root flatpak remote-delete --system --force fedora' ]]

# Setup failures never reach installation or delete the Fedora remote.
failure='root flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo'
events=() actual=0
action_prepare_flatpak fedora '' || actual=$?
[[ "$actual" == 7 && "${#events[@]}" == 1 ]]
available=0 failure='root apt update' events=() actual=0
action_prepare_flatpak debian '' || actual=$?
[[ "$actual" == 7 && "${events[*]}" == 'require apt root apt update' ]]
failure='' available=1

# Query, enable and delete failures retain their status.
query_status=9 events=() actual=0
action_prepare_flatpak fedora '' || actual=$?
[[ "$actual" == 9 && "${#events[@]}" == 0 ]]
query_status=0
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tdisabled\nfedora\thttps://example.org/fedora\t\tsystem'
failure='root flatpak remote-modify --system --enable flathub' events=() actual=0
action_prepare_flatpak fedora '' || actual=$?
[[ "$actual" == 7 && "${#events[@]}" == 1 ]]
remote_rows=$'flathub\thttps://dl.flathub.org/repo/\t\tsystem\nfedora\thttps://example.org/fedora\t\tsystem'
failure='root flatpak remote-delete --system --force fedora' events=() actual=0
action_prepare_flatpak fedora '' || actual=$?
[[ "$actual" == 7 && "${events[-1]}" == "$failure" ]]
failure=''

# Installation accepts confirmations for each selected ID and stops on error.
events=()
action_install_flatpak_apps fedora ''
[[ "${events[*]}" == 'flatpak install -y org.telegram.desktop flatpak install -y md.obsidian.Obsidian' ]]
failure='flatpak install -y org.telegram.desktop' events=() actual=0
action_install_flatpak_apps fedora '' || actual=$?
[[ "$actual" == 7 && "${#events[@]}" == 1 ]]
workflow_select_packages flatpak_apps
available=0 events=()
action_prepare_flatpak fedora ''
action_install_flatpak_apps fedora ''
[[ "${#events[@]}" == 0 ]]
catalog_finish_handler finish_handler flatpak_apps
[[ "$finish_handler" == action_install_flatpak_apps ]]

printf 'Flatpak procedure validation passed.\n'
