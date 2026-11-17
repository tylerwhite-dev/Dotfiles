#!/usr/bin/env bash

package_group native native_desktop_arch_apps_packages \
  firefox alacritty ghostty veracrypt virtualbox gcolor3
package_group native native_desktop_arch_development_packages zed qtcreator docker
package_group native native_desktop_arch_system_packages \
  gparted timeshift virtualbox-host-dkms linux-headers \
  dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g
package_group native native_desktop_arch_dependencies_packages \
  xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor

package_group native native_desktop_debian_apps_packages firefox-esr alacritty
package_group native native_desktop_debian_development_packages \
  build-essential qt6-base-dev qtcreator qt6-declarative-dev \
  qml6-module-qtquick qml6-module-qtquick-controls
package_group native native_desktop_debian_system_packages gparted timeshift
package_group native native_desktop_debian_dependencies_packages wl-clipboard wmctrl

package_group native native_desktop_fedora_apps_packages firefox alacritty
package_group native native_desktop_fedora_system_packages gparted timeshift
package_group native native_desktop_fedora_dependencies_packages wl-clipboard wmctrl

package_category native native_desktop_arch_apps "Applications" native_desktop_arch_apps_packages
package_category native native_desktop_arch_development "Development" native_desktop_arch_development_packages
package_category native native_desktop_arch_system "System" native_desktop_arch_system_packages
package_category native native_desktop_arch_dependencies "Dependencies" native_desktop_arch_dependencies_packages
package_category native native_desktop_debian_apps "Applications" native_desktop_debian_apps_packages
package_category native native_desktop_debian_development "Development" native_desktop_debian_development_packages
package_category native native_desktop_debian_system "System" native_desktop_debian_system_packages
package_category native native_desktop_debian_dependencies "Dependencies" native_desktop_debian_dependencies_packages
package_category native native_desktop_fedora_apps "Applications" native_desktop_fedora_apps_packages
package_category native native_desktop_fedora_system "System" native_desktop_fedora_system_packages
package_category native native_desktop_fedora_dependencies "Dependencies" native_desktop_fedora_dependencies_packages

# Supplies editable defaults only for the desktop preset.
native_desktop_default_packages() {
  local -n __native_desktop_defaults_result="$1"
  local platform="$2" mode="$3"
  __native_desktop_defaults_result=()
  [[ "$mode" == desktop ]] || return 0
  case "$platform" in
    arch) __native_desktop_defaults_result=(
      firefox alacritty zed
      dosfstools e2fsprogs btrfs-progs xfsprogs exfatprogs ntfs-3g
    ) ;;
    debian) __native_desktop_defaults_result=(firefox-esr alacritty) ;;
    fedora) __native_desktop_defaults_result=(firefox alacritty) ;;
  esac
}

# Reports installed candidates, failing if the local database cannot be read.
native_desktop_installed_packages() {
  local -n __native_desktop_installed_result="$1"
  shift
  local native_platform native_name __native_desktop_output __native_desktop_package
  local __native_desktop_status
  local -A __native_desktop_installed_set=()
  __native_desktop_installed_result=()
  environment_detect native_platform native_name || return
  case "$native_platform" in
    arch) __native_desktop_output="$(LC_ALL=C pacman -Qq)" || return ;;
    debian) __native_desktop_output="$(LC_ALL=C dpkg-query -W -f='${db:Status-Status}\t${binary:Package}\n')" || return ;;
    fedora) __native_desktop_output="$(LC_ALL=C rpm -qa --qf '%{NAME}\n')" || return ;;
    *) return 1 ;;
  esac
  while IFS= read -r __native_desktop_package; do
    [[ -n "$__native_desktop_package" ]] || continue
    if [[ "$native_platform" == debian ]]; then
      __native_desktop_status="${__native_desktop_package%%$'\t'*}"
      [[ "$__native_desktop_status" == installed ]] || continue
      __native_desktop_package="${__native_desktop_package#*$'\t'}"
      __native_desktop_package="${__native_desktop_package%%:*}"
    fi
    __native_desktop_installed_set["$__native_desktop_package"]=1
  done <<< "$__native_desktop_output"
  for __native_desktop_package in "$@"; do
    if [[ -v "__native_desktop_installed_set[$__native_desktop_package]" ]]; then
      __native_desktop_installed_result+=("$__native_desktop_package")
    fi
  done
}

action_install_native_desktop() {
  local platform="$1"
  local -a selected=()
  workflow_selected_packages selected native_desktop || return
  ((${#selected[@]})) || return 0
  executor_install_native_items "$platform" package "${selected[@]}"
}

procedure_define native_desktop
procedure_handler native_desktop action_install_native_desktop
procedure_platforms native_desktop arch debian fedora
procedure_requires_root native_desktop arch debian fedora
procedure_selectable native_desktop
procedure_installed_probe native_desktop native_desktop_installed_packages
procedure_defaults_handler native_desktop native_desktop_default_packages
procedure_packages_for_platform native_desktop arch \
  native native_desktop_arch_apps native native_desktop_arch_development \
  native native_desktop_arch_system native native_desktop_arch_dependencies
procedure_packages_for_platform native_desktop debian \
  native native_desktop_debian_apps native native_desktop_debian_development \
  native native_desktop_debian_system native native_desktop_debian_dependencies
procedure_packages_for_platform native_desktop fedora \
  native native_desktop_fedora_apps native native_desktop_fedora_system \
  native native_desktop_fedora_dependencies
message_define procedure.native_desktop.question "Select Native desktop packages to install:"
message_define procedure.native_desktop.label "Install Native desktop packages"
message_define procedure.native_desktop.description \
  "Install selected desktop packages from the distribution repositories."
