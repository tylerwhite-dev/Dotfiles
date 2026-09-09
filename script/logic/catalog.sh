#!/usr/bin/env bash

declare -ag _CATALOG_PROCEDURE_IDS=()
declare -Ag _CATALOG_PROCEDURE_HANDLER=()
declare -Ag _CATALOG_PROCEDURE_PLATFORMS=()
declare -Ag _CATALOG_PROCEDURE_REQUIREMENT=()
declare -Ag _CATALOG_PROCEDURE_REQUIRES_ROOT=()
declare -Ag _CATALOG_PROCEDURE_PACKAGE_REFS=()
declare -Ag _CATALOG_PACKAGE_GROUPS=()

# Registers a package list under a unique source and group name.
package_group() {
  local source="$1"
  local group="$2"
  shift 2

  local key="${source}:${group}"

  if [[ -v "_CATALOG_PACKAGE_GROUPS[$key]" ]]; then
    printf 'Package group declared more than once: %s\n' "$key" >&2
    return 1
  fi

  _CATALOG_PACKAGE_GROUPS["$key"]="$*"
}

# Starts a procedure record with empty optional fields.
procedure_define() {
  local id="$1"

  if [[ -v "_CATALOG_PROCEDURE_HANDLER[$id]" ]]; then
    printf 'Procedure declared more than once: %s\n' "$id" >&2
    return 1
  fi

  _CATALOG_PROCEDURE_IDS+=("$id")
  _CATALOG_PROCEDURE_HANDLER["$id"]=""
  _CATALOG_PROCEDURE_PLATFORMS["$id"]=""
  _CATALOG_PROCEDURE_REQUIREMENT["$id"]=""
  _CATALOG_PROCEDURE_REQUIRES_ROOT["$id"]="no"
  _CATALOG_PROCEDURE_PACKAGE_REFS["$id"]=""
}

# Fails when a declaration refers to an unknown procedure ID.
_catalog_require_procedure() {
  local id="$1"

  if [[ ! -v "_CATALOG_PROCEDURE_HANDLER[$id]" ]]; then
    printf 'Unknown procedure: %s\n' "$id" >&2
    return 1
  fi
}

# Assigns the action function used to execute a procedure.
procedure_handler() {
  _catalog_require_procedure "$1" || return
  _CATALOG_PROCEDURE_HANDLER["$1"]="$2"
}

# Assigns the platform families on which a procedure is available.
procedure_platforms() {
  local id="$1"
  shift

  _catalog_require_procedure "$id" || return
  _CATALOG_PROCEDURE_PLATFORMS["$id"]="$*"
}

# Assigns an optional procedure dependency.
procedure_requires() {
  _catalog_require_procedure "$1" || return
  _CATALOG_PROCEDURE_REQUIREMENT["$1"]="$2"
}

# Marks a procedure as requiring root privileges.
procedure_requires_root() {
  _catalog_require_procedure "$1" || return
  _CATALOG_PROCEDURE_REQUIRES_ROOT["$1"]="yes"
}

# Attaches one or more source and package-group references to a procedure.
procedure_packages() {
  local id="$1"
  shift

  local package_source
  local package_group_name
  local reference

  _catalog_require_procedure "$id" || return

  if (($# == 0 || $# % 2 != 0)); then
    printf 'Package groups for procedure %s must be provided in pairs.\n' "$id" >&2
    return 1
  fi

  while (($# > 0)); do
    package_source="$1"
    package_group_name="$2"
    shift 2
    reference="${package_source}:${package_group_name}"
    _CATALOG_PROCEDURE_PACKAGE_REFS["$id"]+="${_CATALOG_PROCEDURE_PACKAGE_REFS[$id]:+ }${reference}"
  done
}

# Copies the declaration-order procedure IDs into a caller-owned array.
catalog_procedure_ids() {
  local -n result_ref="$1"
  result_ref=("${_CATALOG_PROCEDURE_IDS[@]}")
}

# Returns the action handler registered for a procedure.
catalog_handler() {
  printf -v "$1" '%s' "${_CATALOG_PROCEDURE_HANDLER[$2]}"
}

# Returns the procedure ID required by another procedure, if any.
catalog_requirement() {
  printf -v "$1" '%s' "${_CATALOG_PROCEDURE_REQUIREMENT[$2]}"
}

# Returns whether a procedure was marked as requiring root privileges.
catalog_requires_root() {
  printf -v "$1" '%s' "${_CATALOG_PROCEDURE_REQUIRES_ROOT[$2]}"
}

# Checks whether a procedure supports the requested platform family.
catalog_is_available() {
  local id="$1"
  local platform="$2"
  local platforms=" ${_CATALOG_PROCEDURE_PLATFORMS[$id]} "

  [[ "$platforms" == *" ${platform} "* ]]
}

# Resolves @distribution references to the current platform package group.
_catalog_resolve_package_reference() {
  local result_name="$1"
  local reference="$2"
  local platform="$3"
  local source="${reference%%:*}"
  local group="${reference#*:}"

  if [[ "$group" == "@distribution" ]]; then
    group="$platform"
  fi

  printf -v "$result_name" '%s' "${source}:${group}"
}

# Expands a procedure's package references into a caller-owned package array.
catalog_packages() {
  local -n result_ref="$1"
  local id="$2"
  local platform="$3"
  local requested_source="${4:-}"
  local reference
  local source
  local key
  local -a group_packages=()
  local matched="no"

  result_ref=()

  for reference in ${_CATALOG_PROCEDURE_PACKAGE_REFS[$id]}; do
    source="${reference%%:*}"
    if [[ -n "$requested_source" && "$source" != "$requested_source" ]]; then
      continue
    fi

    _catalog_resolve_package_reference key "$reference" "$platform"
    if [[ ! -v "_CATALOG_PACKAGE_GROUPS[$key]" ]]; then
      printf 'Unknown package group: %s\n' "$key" >&2
      return 1
    fi

    read -r -a group_packages <<< "${_CATALOG_PACKAGE_GROUPS[$key]}"
    result_ref+=("${group_packages[@]}")
    matched="yes"
  done

  if [[ -n "$requested_source" && "$matched" == "no" ]]; then
    printf 'Procedure %s has no package group for source: %s\n' \
      "$id" "$requested_source" >&2
    return 1
  fi
}

# Verifies that all required message keys exist for one procedure.
_catalog_validate_messages() {
  local id="$1"
  local key

  for key in question label description; do
    if ! message_exists "procedure.${id}.${key}"; then
      printf 'Procedure %s has no %s message.\n' "$id" "$key" >&2
      return 1
    fi
  done
}

# Verifies that every package reference points to an existing group.
_catalog_validate_package_references() {
  local id="$1"
  local reference
  local platform
  local key

  for reference in ${_CATALOG_PROCEDURE_PACKAGE_REFS[$id]}; do
    if [[ "${reference#*:}" == "@distribution" ]]; then
      for platform in ${_CATALOG_PROCEDURE_PLATFORMS[$id]}; do
        _catalog_resolve_package_reference key "$reference" "$platform"
        if [[ ! -v "_CATALOG_PACKAGE_GROUPS[$key]" ]]; then
          printf 'Procedure %s references an unknown package group: %s\n' "$id" "$key" >&2
          return 1
        fi
      done
    else
      _catalog_resolve_package_reference key "$reference" ""
      if [[ ! -v "_CATALOG_PACKAGE_GROUPS[$key]" ]]; then
        printf 'Procedure %s references an unknown package group: %s\n' "$id" "$key" >&2
        return 1
      fi
    fi
  done
}

# Validates the complete catalog before the questionnaire starts.
catalog_validate() {
  local id
  local handler
  local requirement
  local -A seen=()

  if ((${#_CATALOG_PROCEDURE_IDS[@]} == 0)); then
    printf 'No setup procedures were declared.\n' >&2
    return 1
  fi

  for id in "${_CATALOG_PROCEDURE_IDS[@]}"; do
    handler="${_CATALOG_PROCEDURE_HANDLER[$id]}"
    requirement="${_CATALOG_PROCEDURE_REQUIREMENT[$id]}"

    if [[ ! "$id" =~ ^[a-z][a-z0-9_]*$ ]]; then
      printf 'Invalid procedure ID: %s\n' "$id" >&2
      return 1
    fi
    if [[ -z "$handler" || ! "$handler" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      printf 'Invalid handler for procedure %s: %s\n' "$id" "$handler" >&2
      return 1
    fi
    if ! declare -F "$handler" >/dev/null; then
      printf 'Procedure %s references an unknown handler: %s\n' "$id" "$handler" >&2
      return 1
    fi
    if [[ -z "${_CATALOG_PROCEDURE_PLATFORMS[$id]}" ]]; then
      printf 'Procedure %s has no supported platforms.\n' "$id" >&2
      return 1
    fi
    if [[ -n "$requirement" && ! -v "seen[$requirement]" ]]; then
      printf 'Procedure %s requires a procedure that is missing or declared later: %s\n' \
        "$id" "$requirement" >&2
      return 1
    fi
    if [[ "${_CATALOG_PROCEDURE_REQUIRES_ROOT[$id]}" != "yes" && \
      "${_CATALOG_PROCEDURE_REQUIRES_ROOT[$id]}" != "no" ]]; then
      printf 'Procedure %s has an invalid root requirement.\n' "$id" >&2
      return 1
    fi

    _catalog_validate_messages "$id" || return
    _catalog_validate_package_references "$id" || return
    seen["$id"]=1
  done
}
