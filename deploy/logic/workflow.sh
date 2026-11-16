#!/usr/bin/env bash

declare -Ag _WORKFLOW_SELECTIONS=()
declare -Ag _WORKFLOW_PACKAGE_SELECTIONS=()

# Clears selections, including procedures removed from the execution queue.
workflow_reset() {
  _WORKFLOW_SELECTIONS=()
  _WORKFLOW_PACKAGE_SELECTIONS=()
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
  if (($#)); then
    workflow_select "$procedure_id" yes
  else
    workflow_select "$procedure_id" no
  fi
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

# Builds distinct preset and installed outputs, publishing only on success.
# Outputs must be distinct direct array names, outside the __workflow_presets_ prefix.
# Returns 1 on an installed probe failure and 2 on a defaults handler failure.
workflow_package_presets() {
  local -n __workflow_presets_result="$1" __workflow_presets_installed_result="$2"
  local __workflow_presets_id="$3" __workflow_presets_platform="$4" __workflow_presets_mode="$5"
  shift 5
  local __workflow_presets_handler __workflow_presets_package
  local -a __workflow_presets_candidates=("$@")
  local -a __workflow_presets_installed=() __workflow_presets_defaults=() __workflow_presets_merged=()

  __workflow_presets_result=()
  __workflow_presets_installed_result=()
  workflow_installed_packages __workflow_presets_installed "$__workflow_presets_id" \
    "${__workflow_presets_candidates[@]}" || return 1
  catalog_defaults_handler __workflow_presets_handler "$__workflow_presets_id"
  if [[ -n "$__workflow_presets_handler" ]]; then
    "$__workflow_presets_handler" __workflow_presets_defaults \
      "$__workflow_presets_platform" "$__workflow_presets_mode" || return 2
  fi
  for __workflow_presets_package in "${__workflow_presets_installed[@]}" "${__workflow_presets_defaults[@]}"; do
    if [[ " ${__workflow_presets_candidates[*]} " == *" $__workflow_presets_package "* &&
          " ${__workflow_presets_merged[*]} " != *" $__workflow_presets_package "* ]]; then
      __workflow_presets_merged+=("$__workflow_presets_package")
    fi
  done
  __workflow_presets_result=("${__workflow_presets_merged[@]}")
  __workflow_presets_installed_result=("${__workflow_presets_installed[@]}")
}

# Resolves needs in consumer order, recording each mapped need once.
workflow_native_requirements() {
  local -n __workflow_requirements_names_result="$1" __workflow_requirements_consumers_result="$2"
  local __workflow_requirements_platform="$3" __workflow_requirements_mode="$4"
  local __workflow_requirements_id __workflow_requirements_name __workflow_requirements_resolved
  local __workflow_requirements_ready_probe __workflow_requirements_index __workflow_requirements_consumer
  local -a __workflow_requirements_selected=() __workflow_requirements_packages=() __workflow_requirements_needs=()
  local -a __workflow_requirements_names=() __workflow_requirements_consumers=() __workflow_requirements_sources=()
  local -A __workflow_requirements_seen=()
  __workflow_requirements_names_result=(); __workflow_requirements_consumers_result=()
  if [[ "$__workflow_requirements_mode" == optionals ]]; then
    workflow_selected_optionals __workflow_requirements_selected "$__workflow_requirements_platform"
  else
    workflow_selected __workflow_requirements_selected "$__workflow_requirements_platform"
  fi
  for __workflow_requirements_id in "${__workflow_requirements_selected[@]}"; do
    catalog_ready_probe __workflow_requirements_ready_probe "$__workflow_requirements_id"
    if [[ -n "$__workflow_requirements_ready_probe" ]] && "$__workflow_requirements_ready_probe"; then continue; fi
    workflow_selected_packages __workflow_requirements_packages "$__workflow_requirements_id"
    __workflow_requirements_sources=("$__workflow_requirements_id" "${__workflow_requirements_packages[@]}")
    for __workflow_requirements_index in "${!__workflow_requirements_sources[@]}"; do
      __workflow_requirements_consumer="${__workflow_requirements_sources[__workflow_requirements_index]}"
      if ((__workflow_requirements_index == 0)); then
        catalog_procedure_needs __workflow_requirements_needs "$__workflow_requirements_id" || return
      else
        catalog_package_needs __workflow_requirements_needs "$__workflow_requirements_id" \
          "$__workflow_requirements_platform" "$__workflow_requirements_consumer" || return
      fi
      for __workflow_requirements_name in "${__workflow_requirements_needs[@]}"; do
        [[ ! -v "__workflow_requirements_seen[$__workflow_requirements_name]" ]] || continue
        catalog_native_requirement __workflow_requirements_resolved \
          "$__workflow_requirements_name" "$__workflow_requirements_platform"
        [[ -n "$__workflow_requirements_resolved" ]] || continue
        __workflow_requirements_names+=("$__workflow_requirements_name")
        __workflow_requirements_consumers+=("$__workflow_requirements_consumer")
        __workflow_requirements_seen["$__workflow_requirements_name"]=1
      done
    done
  done
  __workflow_requirements_names_result=("${__workflow_requirements_names[@]}")
  __workflow_requirements_consumers_result=("${__workflow_requirements_consumers[@]}")
}
