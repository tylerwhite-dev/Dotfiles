#!/usr/bin/env bash

declare -ag _CATALOG_PROCEDURE_IDS=()
declare -Ag _CATALOG_PROCEDURE_HANDLER=()
declare -Ag _CATALOG_PROCEDURE_FINISH_HANDLER=()
declare -Ag _CATALOG_PROCEDURE_PLATFORMS=()
declare -Ag _CATALOG_PROCEDURE_REQUIREMENT=()
declare -Ag _CATALOG_PROCEDURE_REQUIRES_ROOT=()
declare -Ag _CATALOG_PROCEDURE_SELECTABLE=()
declare -Ag _CATALOG_PROCEDURE_PACKAGE_REFS=()
declare -Ag _CATALOG_PACKAGE_GROUPS=()
declare -Ag _CATALOG_PACKAGE_CATEGORY_LABELS=()
declare -Ag _CATALOG_PACKAGE_CATEGORY_REFS=()

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
  if [[ -v "_CATALOG_PACKAGE_CATEGORY_LABELS[$key]" ]]; then
    printf 'Package group name is already used by a category: %s\n' "$key" >&2
    return 1
  fi

  _CATALOG_PACKAGE_GROUPS["$key"]="$*"
}

# Registers a labeled, ordered set of package groups for checkbox selection.
package_category() {
  local source="$1"
  local category="$2"
  local label="$3"
  shift 3

  local key="${source}:${category}"
  local member
  local member_key

  if [[ -v "_CATALOG_PACKAGE_CATEGORY_LABELS[$key]" ]]; then
    printf 'Package category declared more than once: %s\n' "$key" >&2
    return 1
  fi
  if [[ -v "_CATALOG_PACKAGE_GROUPS[$key]" ]]; then
    printf 'Package category name is already used by a group: %s\n' "$key" >&2
    return 1
  fi
  if [[ -z "$label" ]]; then
    printf 'Package category %s needs a label.\n' "$key" >&2
    return 1
  fi
  if (($# == 0)); then
    printf 'Package category %s needs at least one package group.\n' "$key" >&2
    return 1
  fi

  for member in "$@"; do
    member_key="${source}:${member}"
    if [[ ! -v "_CATALOG_PACKAGE_GROUPS[$member_key]" ]]; then
      printf 'Package category %s references an unknown package group: %s\n' \
        "$key" "$member_key" >&2
      return 1
    fi
    if [[ -z "${_CATALOG_PACKAGE_GROUPS[$member_key]}" ]]; then
      printf 'Package category %s references an empty package group: %s\n' \
        "$key" "$member_key" >&2
      return 1
    fi
  done

  _CATALOG_PACKAGE_CATEGORY_LABELS["$key"]="$label"
  _CATALOG_PACKAGE_CATEGORY_REFS["$key"]="$*"
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
  _CATALOG_PROCEDURE_FINISH_HANDLER["$id"]=""
  _CATALOG_PROCEDURE_PLATFORMS["$id"]=""
  _CATALOG_PROCEDURE_REQUIREMENT["$id"]=""
  _CATALOG_PROCEDURE_REQUIRES_ROOT["$id"]=""
  _CATALOG_PROCEDURE_SELECTABLE["$id"]="no"
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

# Assigns an optional handler to run with direct terminal output after the action.
procedure_finish_handler() {
  _catalog_require_procedure "$1" || return
  _CATALOG_PROCEDURE_FINISH_HANDLER["$1"]="$2"
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

# Marks a procedure as requiring root privileges on the listed platforms.
procedure_requires_root() {
  local id="$1"
  shift

  _catalog_require_procedure "$id" || return

  if (($# == 0)); then
    printf 'Root requirement for procedure %s needs at least one platform.\n' "$id" >&2
    return 1
  fi

  _CATALOG_PROCEDURE_REQUIRES_ROOT["$id"]="$*"
}

# Marks a procedure as offering a package-by-package checkbox selection.
procedure_selectable() {
  _catalog_require_procedure "$1" || return
  _CATALOG_PROCEDURE_SELECTABLE["$1"]="yes"
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

# Returns the optional direct-output handler for a procedure.
catalog_finish_handler() {
  printf -v "$1" '%s' "${_CATALOG_PROCEDURE_FINISH_HANDLER[$2]}"
}

# Returns the procedure ID required by another procedure, if any.
catalog_requirement() {
  printf -v "$1" '%s' "${_CATALOG_PROCEDURE_REQUIREMENT[$2]}"
}

# Returns whether a procedure requires root privileges on a platform.
catalog_requires_root() {
  local platforms=" ${_CATALOG_PROCEDURE_REQUIRES_ROOT[$2]:-} "

  if [[ "$platforms" == *" ${3} "* ]]; then
    printf -v "$1" '%s' yes
  else
    printf -v "$1" '%s' no
  fi
}

# Copies a procedure's selectable flag into the caller-provided variable.
catalog_is_selectable() {
  printf -v "$1" '%s' "${_CATALOG_PROCEDURE_SELECTABLE[$2]:-no}"
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

# Maps one resolved reference to the package group keys it stands for. A
# category expands to its members in declaration order, a group to itself.
# The context names the declaration being reported in error messages.
_catalog_reference_group_keys() {
  local -n result_ref="$1"
  local key="$2"
  local context="${3:-Package set}"
  local member
  local member_key

  result_ref=()

  if [[ -v "_CATALOG_PACKAGE_CATEGORY_REFS[$key]" ]]; then
    for member in ${_CATALOG_PACKAGE_CATEGORY_REFS[$key]}; do
      member_key="${key%%:*}:${member}"
      if [[ ! -v "_CATALOG_PACKAGE_GROUPS[$member_key]" ]]; then
        printf '%s references an unknown package group: %s\n' \
          "$context" "$member_key" >&2
        result_ref=()
        return 1
      fi
      result_ref+=("$member_key")
    done
    return 0
  fi

  if [[ -v "_CATALOG_PACKAGE_GROUPS[$key]" ]]; then
    result_ref=("$key")
    return 0
  fi

  printf '%s references an unknown package group: %s\n' "$context" "$key" >&2
  return 1
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
  local group_key
  local -a group_keys=()
  local -a group_packages=()
  local matched="no"

  result_ref=()

  for reference in ${_CATALOG_PROCEDURE_PACKAGE_REFS[$id]}; do
    source="${reference%%:*}"
    if [[ -n "$requested_source" && "$source" != "$requested_source" ]]; then
      continue
    fi

    _catalog_resolve_package_reference key "$reference" "$platform"
    _catalog_reference_group_keys group_keys "$key" "Procedure $id" || return

    for group_key in "${group_keys[@]}"; do
      read -r -a group_packages <<< "${_CATALOG_PACKAGE_GROUPS[$group_key]}"
      result_ref+=("${group_packages[@]}")
    done
    matched="yes"
  done

  if [[ -n "$requested_source" && "$matched" == "no" ]]; then
    printf 'Procedure %s has no package group for source: %s\n' \
      "$id" "$requested_source" >&2
    return 1
  fi
}

# Returns the group display texts and row kinds used to render a procedure's
# package selection. A row of kind g opens a group that owns every following
# item row. Groups referenced outside a category are appended under one
# fallback group. When no reference is a category the result is a plain item
# list with no group rows.
catalog_package_rows() {
  local -n rows_ref="$1"
  local -n kinds_ref="$2"
  local id="$3"
  local platform="$4"
  local requested_source="${5:-}"
  local reference
  local source
  local key
  local group_key
  local index
  local -a group_keys=()
  local -a group_packages=()
  local -a loose_keys=()
  local other_label
  local any_category="no"
  local matched="no"

  rows_ref=()
  kinds_ref=()

  for reference in ${_CATALOG_PROCEDURE_PACKAGE_REFS[$id]}; do
    source="${reference%%:*}"
    if [[ -n "$requested_source" && "$source" != "$requested_source" ]]; then
      continue
    fi

    _catalog_resolve_package_reference key "$reference" "$platform"
    _catalog_reference_group_keys group_keys "$key" "Procedure $id" || return
    matched="yes"

    if [[ ! -v "_CATALOG_PACKAGE_CATEGORY_LABELS[$key]" ]]; then
      loose_keys+=("${group_keys[@]}")
      continue
    fi

    rows_ref+=("${_CATALOG_PACKAGE_CATEGORY_LABELS[$key]}")
    kinds_ref+=(g)
    any_category="yes"
    for group_key in "${group_keys[@]}"; do
      read -r -a group_packages <<< "${_CATALOG_PACKAGE_GROUPS[$group_key]}"
      for ((index = 0; index < ${#group_packages[@]}; index++)); do
        rows_ref+=("${group_packages[$index]}")
        kinds_ref+=(i)
      done
    done
  done

  if [[ -n "$requested_source" && "$matched" == "no" ]]; then
    printf 'Procedure %s has no package group for source: %s\n' \
      "$id" "$requested_source" >&2
    return 1
  fi

  if ((${#loose_keys[@]} > 0)) && [[ "$any_category" == "yes" ]]; then
    message_format other_label package_category_other
    rows_ref+=("$other_label")
    kinds_ref+=(g)
  fi
  for group_key in "${loose_keys[@]}"; do
    read -r -a group_packages <<< "${_CATALOG_PACKAGE_GROUPS[$group_key]}"
    for ((index = 0; index < ${#group_packages[@]}; index++)); do
      rows_ref+=("${group_packages[$index]}")
      kinds_ref+=(i)
    done
  done

  if ((${#rows_ref[@]} == 0)); then
    printf 'Procedure %s resolved to an empty package selection.\n' "$id" >&2
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

# Verifies that every package reference points to an existing group or category.
_catalog_validate_package_references() {
  local id="$1"
  local reference
  local platform
  local key
  local -a group_keys=()

  for reference in ${_CATALOG_PROCEDURE_PACKAGE_REFS[$id]}; do
    if [[ "${reference#*:}" == "@distribution" ]]; then
      for platform in ${_CATALOG_PROCEDURE_PLATFORMS[$id]}; do
        _catalog_resolve_package_reference key "$reference" "$platform"
        _catalog_reference_group_keys group_keys "$key" "Procedure $id" || return 1
      done
    else
      _catalog_resolve_package_reference key "$reference" ""
      _catalog_reference_group_keys group_keys "$key" "Procedure $id" || return 1
    fi
  done
}

# Validates the complete catalog before the questionnaire starts.
catalog_validate() {
  local id
  local handler
  local finish_handler
  local requirement
  local platform
  local -A seen=()

  if ((${#_CATALOG_PROCEDURE_IDS[@]} == 0)); then
    printf 'No setup procedures were declared.\n' >&2
    return 1
  fi

  for id in "${_CATALOG_PROCEDURE_IDS[@]}"; do
    handler="${_CATALOG_PROCEDURE_HANDLER[$id]}"
    finish_handler="${_CATALOG_PROCEDURE_FINISH_HANDLER[$id]}"
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
    if [[ -n "$finish_handler" ]]; then
      if [[ ! "$finish_handler" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || \
        ! declare -F "$finish_handler" >/dev/null; then
        printf 'Procedure %s references an unknown finish handler: %s\n' \
          "$id" "$finish_handler" >&2
        return 1
      fi
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
    for platform in ${_CATALOG_PROCEDURE_REQUIRES_ROOT[$id]}; do
      if ! catalog_is_available "$id" "$platform"; then
        printf 'Procedure %s requires root on unsupported platform: %s\n' \
          "$id" "$platform" >&2
        return 1
      fi
    done
    if [[ "${_CATALOG_PROCEDURE_SELECTABLE[$id]}" != "yes" && \
      "${_CATALOG_PROCEDURE_SELECTABLE[$id]}" != "no" ]]; then
      printf 'Procedure %s has an invalid selectable flag.\n' "$id" >&2
      return 1
    fi

    _catalog_validate_messages "$id" || return
    _catalog_validate_package_references "$id" || return
    seen["$id"]=1
  done
}
