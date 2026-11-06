#!/usr/bin/env bash

declare -Ag _WORKFLOW_SELECTIONS=()
declare -Ag _WORKFLOW_PACKAGE_SELECTIONS=()

# Clears selections, including procedures removed from the execution queue.
workflow_reset() {
  local -a procedure_ids=()
  local procedure_id

  _WORKFLOW_SELECTIONS=()
  _WORKFLOW_PACKAGE_SELECTIONS=()
  catalog_procedure_ids procedure_ids
  for procedure_id in "${procedure_ids[@]}"; do
    _WORKFLOW_SELECTIONS["$procedure_id"]="no"
    _WORKFLOW_PACKAGE_SELECTIONS["$procedure_id"]=""
  done
}

# Stores a validated yes/no answer for one procedure.
workflow_select() {
  local procedure_id="$1"
  local selection="$2"

  if [[ "$selection" != "yes" && "$selection" != "no" ]]; then
    return 2
  fi

  _WORKFLOW_SELECTIONS["$procedure_id"]="$selection"
}

# Reads a procedure's current answer into the caller-provided variable.
workflow_selection() {
  printf -v "$1" '%s' "${_WORKFLOW_SELECTIONS[$2]:-no}"
}

# Checks whether a procedure's prerequisite is selected or absent.
workflow_requirement_is_selected() {
  local procedure_id="$1"
  local requirement

  catalog_requirement requirement "$procedure_id"
  [[ -z "$requirement" || "${_WORKFLOW_SELECTIONS[$requirement]:-no}" == "yes" ]]
}

# Lists enabled procedures supported by the platform in configured queue order.
workflow_available() {
  local -n __workflow_available_result_ref="$1"
  local __workflow_available_platform="$2"
  local -a __workflow_available_procedure_ids=()
  local __workflow_available_procedure_id

  __workflow_available_result_ref=()
  catalog_procedure_ids __workflow_available_procedure_ids
  for __workflow_available_procedure_id in "${__workflow_available_procedure_ids[@]}"; do
    if [[ -v "SETUP_SCENARIO_PROCEDURES[${SETUP_MODE:-standard}]" && \
          " ${SETUP_SCENARIO_PROCEDURES[${SETUP_MODE:-standard}]} " != *" $__workflow_available_procedure_id "* ]]; then
      continue
    fi
    if catalog_is_available "$__workflow_available_procedure_id" "$__workflow_available_platform"; then
      __workflow_available_result_ref+=("$__workflow_available_procedure_id")
    fi
  done
}

# Lists selectable procedures supported by the requested platform.
workflow_available_optionals() {
  local -n __workflow_optionals_result="$1"
  local __workflow_optionals_platform="$2" __workflow_optionals_id __workflow_optionals_selectable
  local -a __workflow_optionals_available=()
  workflow_available __workflow_optionals_available "$__workflow_optionals_platform"
  __workflow_optionals_result=()
  for __workflow_optionals_id in "${__workflow_optionals_available[@]}"; do
    catalog_is_selectable __workflow_optionals_selectable "$__workflow_optionals_id"
    if [[ "$__workflow_optionals_selectable" == yes ]]; then
      __workflow_optionals_result+=("$__workflow_optionals_id")
    fi
  done
}

# The optionals-only scenario prepares package managers separately, so the
# normal requirement on selecting the core Homebrew procedure does not apply.
workflow_selected_optionals() {
  local -n __workflow_optional_selection_result="$1"
  local __workflow_optional_selection_id
  local -a __workflow_optional_selection_available=()
  workflow_available_optionals __workflow_optional_selection_available "$2"
  __workflow_optional_selection_result=()
  for __workflow_optional_selection_id in "${__workflow_optional_selection_available[@]}"; do
    if [[ "${_WORKFLOW_SELECTIONS[$__workflow_optional_selection_id]:-no}" == yes ]]; then
      __workflow_optional_selection_result+=("$__workflow_optional_selection_id")
    fi
  done
}

# Lists available procedures that are selected with satisfied prerequisites.
workflow_selected() {
  local -n __workflow_selected_result_ref="$1"
  local __workflow_selected_platform="$2"
  local -a __workflow_selected_procedure_ids=()
  local __workflow_selected_procedure_id

  __workflow_selected_result_ref=()
  workflow_available __workflow_selected_procedure_ids "$__workflow_selected_platform"
  for __workflow_selected_procedure_id in "${__workflow_selected_procedure_ids[@]}"; do
    if [[ "${_WORKFLOW_SELECTIONS[$__workflow_selected_procedure_id]:-no}" == "yes" ]] && \
      workflow_requirement_is_selected "$__workflow_selected_procedure_id"; then
      __workflow_selected_result_ref+=("$__workflow_selected_procedure_id")
    fi
  done
}

# Stores the chosen packages for a selectable procedure.
workflow_select_packages() {
  local procedure_id="$1"
  shift

  _WORKFLOW_PACKAGE_SELECTIONS["$procedure_id"]="$*"
}

# Reads a procedure's chosen packages into a caller-owned array.
workflow_selected_packages() {
  local -n result_ref="$1"
  local procedure_id="$2"

  result_ref=()
  if [[ -n "${_WORKFLOW_PACKAGE_SELECTIONS[$procedure_id]:-}" ]]; then
    read -r -a result_ref <<< "${_WORKFLOW_PACKAGE_SELECTIONS[$procedure_id]}"
  fi
}

# Reports which of the given packages a procedure already has installed.
workflow_installed_packages() {
  local -n __workflow_installed_result="$1"
  local __workflow_installed_id="$2"
  shift 2

  local __workflow_installed_probe
  local -a __workflow_installed_found=()

  __workflow_installed_result=()
  catalog_installed_probe __workflow_installed_probe "$__workflow_installed_id"
  [[ -n "$__workflow_installed_probe" ]] || return 0
  "$__workflow_installed_probe" __workflow_installed_found "$@" || return
  __workflow_installed_result=("${__workflow_installed_found[@]}")
}

# Resolves native requirements of the current selection, once per named need.
# Parallel output arrays contain requirement names and the first consumer.
workflow_native_requirements() {
  local -n names_result="$1" consumers_result="$2"
  local platform="$3" mode="$4" id key source package name resolved
  local -a selected=() packages=() candidates=()
  local -A seen=()
  names_result=(); consumers_result=()
  if [[ "$mode" == optionals ]]; then
    workflow_selected_optionals selected "$platform"
  else
    workflow_selected selected "$platform"
  fi
  for id in "${selected[@]}"; do
    for name in ${_CATALOG_PROCEDURE_NEEDS[$id]:-}; do
      [[ ! -v "seen[$name]" ]] || continue
      catalog_native_requirement resolved "$name" "$platform"
      if [[ -n "$resolved" ]]; then
        names_result+=("$name"); consumers_result+=("$id"); seen["$name"]=1
      fi
    done
    workflow_selected_packages packages "$id"
    for key in "${!_CATALOG_PACKAGE_NEEDS[@]}"; do
      source="${key%%:*}"; package="${key#*:}"
      [[ " ${packages[*]} " == *" $package "* ]] || continue
      [[ " ${_CATALOG_PROCEDURE_PACKAGE_REFS[$id]} " == *" $source:"* ]] || continue
      catalog_packages candidates "$id" "$platform" "$source" || return
      [[ " ${candidates[*]} " == *" $package "* ]] || continue
      for name in ${_CATALOG_PACKAGE_NEEDS[$key]}; do
        [[ ! -v "seen[$name]" ]] || continue
        catalog_native_requirement resolved "$name" "$platform"
        if [[ -n "$resolved" ]]; then
          names_result+=("$name"); consumers_result+=("$package"); seen["$name"]=1
        fi
      done
    done
  done
}
