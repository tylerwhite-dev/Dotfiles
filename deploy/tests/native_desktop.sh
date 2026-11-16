#!/usr/bin/env bash
set -Eeuo pipefail
script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "${script_root}/logic/load.sh"

catalog_validate
packages=(); rows=(); kinds=(); items=(); headings=()
catalog_packages packages native_desktop arch native
catalog_package_rows rows kinds native_desktop arch native
for index in "${!rows[@]}"; do
  if [[ "${kinds[index]}" == i ]]; then
    items+=("${rows[index]}")
  else
    headings+=("${rows[index]}")
  fi
done
[[ "${items[*]}" == "${packages[*]}" && "${#packages[@]}" == 24 ]]
[[ "${headings[*]}" == 'Desktop Development Libs' ]]
declare -A seen=()
for package in "${packages[@]}"; do
  [[ ! -v "seen[$package]" ]]
  seen["$package"]=1
done
[[ "${packages[*]}" == 'firefox alacritty ghostty gparted veracrypt virtualbox timeshift gcolor3 zed qtcreator docker virtualbox-host-dkms linux-headers dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor' ]]
_catalog_resolve_package_reference resolved native:@distribution arch
[[ "$resolved" == native:arch ]]
_catalog_resolve_package_reference resolved native:native_desktop_@distribution_desktop arch
[[ "$resolved" == native:native_desktop_arch_desktop ]]
(
  # Validation must expand embedded placeholders for every supported platform.
  procedure_platforms native_desktop arch debian
  if catalog_validate 2>/dev/null; then exit 1; fi
)

# The local database probe intersects candidates and propagates failures.
probe_output=$'firefox\nunrelated'
probe_status=0
pacman() {
  [[ "$*" == '-Qq' ]]
  printf '%s\n' "$probe_output"
  return "$probe_status"
}
native_desktop_installed_packages found firefox ghostty
[[ "${found[*]}" == firefox ]]
probe_output=''
native_desktop_installed_packages found firefox ghostty
[[ "${#found[@]}" == 0 ]]
probe_status=7
actual=0
native_desktop_installed_packages found firefox || actual=$?
[[ "$actual" == 7 && "${#found[@]}" == 0 ]]
probe_status=0

ui_stage() { :; }
ui_multiselect_grouped() {
  local -n result="$1" presets_ref="$6"
  captured_presets=("${presets_ref[@]}")
  result=("${menu_selection[@]}")
}
for SETUP_MODE in standard desktop optionals; do
  for probe_output in '' $'ghostty\nfirefox'; do
    workflow_reset
    menu_selection=(ghostty)
    captured_presets=()
    _questionnaire_read_selectable_packages native_desktop arch 1 1
    expected_presets=()
    if [[ -n "$probe_output" ]]; then expected_presets=(firefox ghostty); fi
    if [[ "$SETUP_MODE" == desktop ]]; then
      for package in firefox alacritty zed dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g; do
        if [[ " ${expected_presets[*]} " != *" $package "* ]]; then
          expected_presets+=("$package")
        fi
      done
    fi
    [[ "${captured_presets[*]}" == "${expected_presets[*]}" ]]
    workflow_selected_packages selected native_desktop
    if [[ -z "$probe_output" ]]; then
      [[ "${selected[*]}" == ghostty ]]
    else
      [[ "${#selected[@]}" == 0 ]]
    fi
  done
done

# No preset mode other than desktop includes the new procedure.
for SETUP_MODE in standard desktop optionals server wsl mac; do
  for platform in arch debian fedora macos; do
    workflow_available available "$platform"
    if [[ "$platform" == arch && "$SETUP_MODE" =~ ^(standard|desktop|optionals)$ ]]; then
      [[ " ${available[*]} " == *' native_desktop '* ]]
    else
      [[ " ${available[*]} " != *' native_desktop '* ]]
    fi
  done
done

# A failed probe prevents menu display, and an empty selection skips installation.
probe_status=7
menu_opened=no
ui_multiselect_grouped() { menu_opened=yes; }
error_report() { reported_error="$1"; }
actual=0
_questionnaire_read_selectable_packages native_desktop arch 1 1 || actual=$?
[[ "$actual" == 1 && "$menu_opened" == no ]]
[[ "$reported_error" == error.installed_packages_probe_failed ]]
calls=()
(
  probe_status=0
  SETUP_MODE=desktop
  failing_defaults() { local -n result="$1"; result=(ghostty); return 8; }
  procedure_defaults_handler native_desktop failing_defaults
  workflow_reset
  actual=0
  _questionnaire_read_selectable_packages native_desktop arch 1 1 || actual=$?
  [[ "$actual" == 1 && "$menu_opened" == no ]]
  [[ "$reported_error" == error.package_defaults_failed ]]
  workflow_selected selected arch
  [[ "${#selected[@]}" == 0 ]]
)
executor_install_native_items() { calls+=("$*"); }
workflow_select_packages native_desktop ghostty
action_install_native_desktop arch
[[ "${calls[*]}" == 'arch package ghostty' ]]
workflow_select_packages native_desktop
action_install_native_desktop arch
[[ "${#calls[@]}" == 1 ]]
printf 'Native desktop validation passed.\n'
