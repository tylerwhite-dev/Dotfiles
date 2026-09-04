#!/usr/bin/env bash

declare -ag STEP_IDS=()
declare -Ag STEP_QUESTION=()
declare -Ag STEP_COMMENT=()
declare -Ag STEP_COMMAND=()
declare -Ag STEP_PLATFORMS=()
declare -Ag STEP_REQUIREMENT=()
declare -Ag STEP_PACKAGE_REFS=()
declare -Ag STEP_SELECTED=()

declare -Ag PACKAGE_GROUPS=()
declare -ag STEPS_PACKAGES=()
STEP_RENDERED_COMMENT=""

package_group() {
  local source="$1"
  local group="$2"
  shift 2

  local key="${source}:${group}"

  if [[ -v "PACKAGE_GROUPS[$key]" ]]; then
    printf 'Package group declared more than once: %s\n' "$key" >&2
    return 1
  fi

  PACKAGE_GROUPS["$key"]="$*"
}

step() {
  local id="$1"
  local question="$2"
  local comment="$3"
  local command="$4"
  local platforms="$5"
  local requirement="${6:-}"

  if [[ -v "STEP_QUESTION[$id]" ]]; then
    printf 'Step declared more than once: %s\n' "$id" >&2
    return 1
  fi

  STEP_IDS+=("$id")
  STEP_QUESTION["$id"]="$question"
  STEP_COMMENT["$id"]="$comment"
  STEP_COMMAND["$id"]="$command"
  STEP_PLATFORMS["$id"]="$platforms"
  STEP_REQUIREMENT["$id"]="$requirement"
  STEP_PACKAGE_REFS["$id"]=""
  STEP_SELECTED["$id"]="no"
}

step_packages() {
  local id="$1"
  shift

  local package_source
  local package_group_name
  local reference

  if [[ ! -v "STEP_QUESTION[$id]" ]]; then
    printf 'Package groups assigned to an unknown step: %s\n' "$id" >&2
    return 1
  fi

  if (($# == 0 || $# % 2 != 0)); then
    printf 'Package groups for step %s must be provided in pairs.\n' "$id" >&2
    return 1
  fi

  while (($# > 0)); do
    package_source="$1"
    package_group_name="$2"
    shift 2

    reference="${package_source}:${package_group_name}"
    STEP_PACKAGE_REFS["$id"]+="${STEP_PACKAGE_REFS[$id]:+ }${reference}"
  done
}

steps_validate() {
  local id
  local command
  local requirement
  local reference
  local package_source
  local package_group_name
  local platform
  local key

  if ((${#STEP_IDS[@]} == 0)); then
    printf 'No setup steps were declared.\n' >&2
    return 1
  fi

  for id in "${STEP_IDS[@]}"; do
    command="${STEP_COMMAND[$id]}"
    requirement="${STEP_REQUIREMENT[$id]}"

    if [[ ! "$id" =~ ^[a-z][a-z0-9_]*$ ]]; then
      printf 'Invalid step ID: %s\n' "$id" >&2
      return 1
    fi

    if [[ -z "${STEP_QUESTION[$id]}" || -z "${STEP_COMMENT[$id]}" ]]; then
      printf 'Step %s must have a question and a comment.\n' "$id" >&2
      return 1
    fi

    if [[ ! "$command" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      printf 'Invalid command for step %s: %s\n' "$id" "$command" >&2
      return 1
    fi

    if ! declare -F "$command" >/dev/null; then
      printf 'Step %s references an unknown execution function: %s\n' "$id" "$command" >&2
      return 1
    fi

    if [[ -n "$requirement" && ! -v "STEP_QUESTION[$requirement]" ]]; then
      printf 'Step %s depends on an unknown step: %s\n' "$id" "$requirement" >&2
      return 1
    fi

    for reference in ${STEP_PACKAGE_REFS[$id]}; do
      package_source="${reference%%:*}"
      package_group_name="${reference#*:}"

      if [[ "$package_group_name" == "@distribution" ]]; then
        for platform in ${STEP_PLATFORMS[$id]}; do
          key="${package_source}:${platform}"

          if [[ ! -v "PACKAGE_GROUPS[$key]" ]]; then
            printf 'Step %s references an unknown package group: %s\n' "$id" "$key" >&2
            return 1
          fi
        done
      else
        key="${package_source}:${package_group_name}"

        if [[ ! -v "PACKAGE_GROUPS[$key]" ]]; then
          printf 'Step %s references an unknown package group: %s\n' "$id" "$key" >&2
          return 1
        fi
      fi
    done
  done

  return 0
}

steps_is_available() {
  local id="$1"
  local platform="$2"
  local supported_platforms=" ${STEP_PLATFORMS[$id]} "

  [[ "$supported_platforms" == *" ${platform} "* ]]
}

steps_requirement_is_selected() {
  local id="$1"
  local requirement="${STEP_REQUIREMENT[$id]}"

  [[ -z "$requirement" || "${STEP_SELECTED[$requirement]}" == "yes" ]]
}

steps_reset_answers() {
  local id

  for id in "${STEP_IDS[@]}"; do
    STEP_SELECTED["$id"]="no"
  done
}

steps_render_comment() {
  local id="$1"
  local platform="$2"
  local reference
  local package_source
  local package_group_name
  local key
  local listed_items=""

  STEP_RENDERED_COMMENT="${STEP_COMMENT[$id]}"

  for reference in ${STEP_PACKAGE_REFS[$id]}; do
    package_source="${reference%%:*}"
    package_group_name="${reference#*:}"

    if [[ "$package_group_name" == "@distribution" ]]; then
      package_group_name="$platform"
    fi

    key="${package_source}:${package_group_name}"

    if [[ ! -v "PACKAGE_GROUPS[$key]" ]]; then
      printf 'Unknown package group: %s\n' "$key" >&2
      return 1
    fi

    listed_items+="${listed_items:+ }${PACKAGE_GROUPS[$key]}"
  done

  if [[ -n "$listed_items" ]]; then
    STEP_RENDERED_COMMENT+=$'\n'
    STEP_RENDERED_COMMENT+="  ${listed_items// /, }"
  fi
}

steps_load_packages() {
  local source="$1"
  local group="$2"
  local key="${source}:${group}"

  if [[ ! -v "PACKAGE_GROUPS[$key]" ]]; then
    printf 'Unknown package group: %s\n' "$key" >&2
    return 1
  fi

  read -r -a STEPS_PACKAGES <<< "${PACKAGE_GROUPS[$key]}"
}

steps_load_step_packages() {
  local id="$1"
  local platform="$2"
  local requested_source="$3"
  local reference
  local package_source
  local package_group_name
  local key
  local -a packages=()
  local matched_group="no"

  STEPS_PACKAGES=()

  for reference in ${STEP_PACKAGE_REFS[$id]}; do
    package_source="${reference%%:*}"
    package_group_name="${reference#*:}"

    if [[ "$package_source" != "$requested_source" ]]; then
      continue
    fi

    if [[ "$package_group_name" == "@distribution" ]]; then
      package_group_name="$platform"
    fi

    key="${package_source}:${package_group_name}"
    matched_group="yes"

    if [[ ! -v "PACKAGE_GROUPS[$key]" ]]; then
      printf 'Unknown package group: %s\n' "$key" >&2
      return 1
    fi

    read -r -a packages <<< "${PACKAGE_GROUPS[$key]}"
    STEPS_PACKAGES+=("${packages[@]}")
  done

  if [[ "$matched_group" == "no" ]]; then
    printf 'Step %s has no package group for source: %s\n' \
      "$id" "$requested_source" >&2
    return 1
  fi
}
