#!/usr/bin/env bash

package_group native native_desktop_arch_desktop_packages \
  firefox alacritty ghostty gparted veracrypt virtualbox timeshift gcolor3
package_group native native_desktop_arch_development_packages zed qtcreator docker
package_group native native_desktop_arch_lib_packages \
  virtualbox-host-dkms linux-headers \
  dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g \
  xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor

package_category native native_desktop_arch_desktop "Desktop" native_desktop_arch_desktop_packages
package_category native native_desktop_arch_development "Development" native_desktop_arch_development_packages
package_category native native_desktop_arch_libs "Libs" native_desktop_arch_lib_packages

# Supplies editable defaults only for the desktop preset on Arch.
native_desktop_default_packages() {
  local -n __native_desktop_defaults_result="$1"
  local platform="$2" mode="$3"
  __native_desktop_defaults_result=()
  if [[ "$mode" == desktop && "$platform" == arch ]]; then
    __native_desktop_defaults_result=(
      firefox alacritty zed
      dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g
    )
  fi
}

# Reports installed candidates from Arch's local package database.
native_desktop_installed_packages() {
  local -n __native_desktop_installed_result="$1"
  shift
  local __native_desktop_output __native_desktop_package
  local -A __native_desktop_installed_set=()
  __native_desktop_installed_result=()
  __native_desktop_output="$(LC_ALL=C pacman -Qq)" || return
  while IFS= read -r __native_desktop_package; do
    [[ -n "$__native_desktop_package" ]] || continue
    __native_desktop_installed_set["$__native_desktop_package"]=1
  done <<< "$__native_desktop_output"
  for __native_desktop_package in "$@"; do
    if [[ -v "__native_desktop_installed_set[$__native_desktop_package]" ]]; then
      __native_desktop_installed_result+=("$__native_desktop_package")
    fi
  done
}

# Installs only the selected, not already installed desktop packages.
action_install_native_desktop() {
  local platform="$1"
  local -a selected=()
  workflow_selected_packages selected native_desktop || return
  ((${#selected[@]})) || return 0
  executor_install_native_items "$platform" package "${selected[@]}"
}

procedure_define native_desktop
procedure_handler native_desktop action_install_native_desktop
procedure_platforms native_desktop arch
procedure_requires_root native_desktop arch
procedure_selectable native_desktop
procedure_installed_probe native_desktop native_desktop_installed_packages
procedure_defaults_handler native_desktop native_desktop_default_packages
procedure_packages native_desktop \
  native native_desktop_@distribution_desktop \
  native native_desktop_@distribution_development \
  native native_desktop_@distribution_libs
message_define procedure.native_desktop.question \
  "Select Native desktop packages to install:"
message_define procedure.native_desktop.label "Install Native desktop packages"
message_define procedure.native_desktop.description \
  "Install selected desktop packages from the distribution repositories."
