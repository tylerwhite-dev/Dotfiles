#!/usr/bin/env bash

declare -Ag _WORKFLOW_SELECTIONS=()

# Resets every declared procedure to an unselected state.
workflow_reset() {
  local -a procedure_ids=()
  local procedure_id

  catalog_procedure_ids procedure_ids
  for procedure_id in "${procedure_ids[@]}"; do
    _WORKFLOW_SELECTIONS["$procedure_id"]="no"
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

# Lists procedures supported by the requested platform in declaration order.
workflow_available() {
  local -n result_ref="$1"
  local platform="$2"
  local -a procedure_ids=()
  local procedure_id

  result_ref=()
  catalog_procedure_ids procedure_ids
  for procedure_id in "${procedure_ids[@]}"; do
    if catalog_is_available "$procedure_id" "$platform"; then
      result_ref+=("$procedure_id")
    fi
  done
}

# Lists available procedures that are selected with satisfied prerequisites.
workflow_selected() {
  local -n result_ref="$1"
  local platform="$2"
  local -a procedure_ids=()
  local procedure_id

  result_ref=()
  catalog_procedure_ids procedure_ids
  for procedure_id in "${procedure_ids[@]}"; do
    if catalog_is_available "$procedure_id" "$platform" && \
      [[ "${_WORKFLOW_SELECTIONS[$procedure_id]:-no}" == "yes" ]] && \
      workflow_requirement_is_selected "$procedure_id"; then
      result_ref+=("$procedure_id")
    fi
  done
}
