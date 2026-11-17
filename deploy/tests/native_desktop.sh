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
[[ "${headings[*]}" == 'Applications Development System Dependencies' ]]
declare -A seen=()
for package in "${packages[@]}"; do
  [[ ! -v "seen[$package]" ]]
  seen["$package"]=1
done
[[ "${packages[*]}" == 'firefox alacritty ghostty veracrypt virtualbox gcolor3 zed qtcreator docker gparted timeshift virtualbox-host-dkms linux-headers dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor' ]]
catalog_packages packages native_desktop debian native
[[ "${packages[*]}" == 'firefox-esr alacritty build-essential qt6-base-dev qtcreator qt6-declarative-dev qml6-module-qtquick qml6-module-qtquick-controls gparted timeshift wl-clipboard wmctrl' ]]
catalog_packages packages native_desktop fedora native
[[ "${packages[*]}" == 'firefox alacritty gparted timeshift wl-clipboard wmctrl' ]]
catalog_package_rows rows kinds native_desktop fedora native
headings=()
for index in "${!rows[@]}"; do [[ "${kinds[index]}" != g ]] || headings+=("${rows[index]}"); done
[[ "${headings[*]}" == 'Applications System Dependencies' ]]
_catalog_resolve_package_reference resolved native:@distribution arch
[[ "$resolved" == native:arch ]]
_catalog_resolve_package_reference resolved native:native_desktop_@distribution_desktop arch
[[ "$resolved" == native:native_desktop_arch_desktop ]]
(
  # Validation rejects missing platform-specific groups.
  procedure_packages_for_platform native_desktop debian native missing_group
  if catalog_validate 2>/dev/null; then exit 1; fi
)

# The local database probe intersects candidates and propagates failures.
probe_output=$'firefox\nunrelated'
probe_status=0
test_platform=arch
environment_detect() { printf -v "$1" '%s' "$test_platform"; printf -v "$2" '%s' fixture; }
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
dpkg-query() { printf '%s\n' "$probe_output"; return "$probe_status"; }
rpm() { printf '%s\n' "$probe_output"; return "$probe_status"; }
test_platform=debian
probe_output=$'installed\tfirefox-esr:amd64\nconfig-files\talacritty'
native_desktop_installed_packages found firefox-esr alacritty
[[ "${found[*]}" == firefox-esr ]]
test_platform=fedora
probe_output=$'firefox\nunrelated'
native_desktop_installed_packages found firefox alacritty
[[ "${found[*]}" == firefox ]]
probe_status=7
actual=0
native_desktop_installed_packages found firefox || actual=$?
[[ "$actual" == 7 && "${#found[@]}" == 0 ]]
probe_status=0
test_platform=arch

for test_platform in debian fedora; do
  native_desktop_default_packages defaults "$test_platform" desktop
  if [[ "$test_platform" == debian ]]; then
    [[ "${defaults[*]}" == 'firefox-esr alacritty' ]]
  else
    [[ "${defaults[*]}" == 'firefox alacritty' ]]
  fi
  native_desktop_default_packages defaults "$test_platform" standard
  [[ "${#defaults[@]}" == 0 ]]
done
test_platform=arch

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
    if [[ "$platform" != macos && "$SETUP_MODE" =~ ^(standard|desktop|optionals)$ ]]; then
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
