ui_color_test=""
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  ui_color_test=$'\033[1;96m'
fi

declare -a _case_statuses=()
declare -a _case_descriptions=()
declare -a _all_summaries=()
_series_name=""
_total_cases=0
_total_pass=0
_total_fail=0
_total_skip=0

_test_msg() {
  printf '%s%s%s\n' "$ui_color_test" "$1" "$ui_color_reset"
}

_series_begin() {
  local name="$1"
  shift
  _series_name="$name"
  _case_statuses=()
  _case_descriptions=()
  printf '\n\n'
  printf '%s%s%s\n' "$ui_color_test" \
    '──────────────────────────────────────────────' \
    "$ui_color_reset"
  printf '\n'
  _test_msg "TEST: ${name}"
  _test_msg "  What to verify: ${*}"
  printf '\n'
}

_series_end() {
  local i status_color pass=0 fail=0 skip=0
  local summary_line

  printf '\n'
  _test_msg "── Summary: ${_series_name} ─────────────────────────────"
  for i in "${!_case_statuses[@]}"; do
    case "${_case_statuses[$i]}" in
      PASS) status_color="$ui_color_success"; ((pass = pass + 1)) ;;
      FAIL) status_color="$ui_color_error"; ((fail = fail + 1)) ;;
      SKIP) status_color="$ui_color_hint"; ((skip = skip + 1)) ;;
      *) status_color="$ui_color_reset" ;;
    esac
    printf '  - %s: %s%s%s\n' \
      "${_case_descriptions[$i]}" \
      "$status_color" "${_case_statuses[$i]}" "$ui_color_reset"
  done

  _total_cases=$((_total_cases + ${#_case_statuses[@]}))
  _total_pass=$((_total_pass + pass))
  _total_fail=$((_total_fail + fail))
  _total_skip=$((_total_skip + skip))

  summary_line="Total ${#_case_statuses[@]} · pass ${pass} · fail ${fail} · skip ${skip}"
  if ((fail > 0)); then
    printf '%s%s%s\n' "$ui_color_error" "$summary_line" "$ui_color_reset"
  else
    printf '%s%s%s\n' "$ui_color_success" "$summary_line" "$ui_color_reset"
  fi
  _all_summaries+=("${_series_name}: ${summary_line}")
}

_final_summary() {
  local line
  local summary_line

  _test_msg "═══════════ FINAL SUMMARY ═══════════"
  for line in "${_all_summaries[@]:-}"; do
    printf '  %s\n' "$line"
  done

  summary_line="Tests: ${#_all_summaries[@]} · cases ${_total_cases} · pass ${_total_pass} · fail ${_total_fail} · skip ${_total_skip}"
  printf '\n'
  if ((_total_fail > 0)); then
    printf '%s%s%s\n\n' "$ui_color_error" "$summary_line" "$ui_color_reset"
  else
    printf '%s%s%s\n\n' "$ui_color_success" "$summary_line" "$ui_color_reset"
  fi
}

_case() {
  local description="$1"
  shift
  local answer=""
  local render_status=0

  if (($# == 0)); then
    printf '%sNo render command for this case — marking as FAIL.%s\n' \
      "$ui_color_error" "$ui_color_reset"
    _case_statuses+=('FAIL')
    _case_descriptions+=("${description}  (no render command)")
    return 0
  fi

  printf '\n'
  _test_msg "▶ ${description}"
  "$@" || render_status=$?
  printf '\n'

  if ((render_status != 0)); then
    printf '%sRender failed with code %d — marking as FAIL.%s\n' \
      "$ui_color_error" "$render_status" "$ui_color_reset"
    _case_statuses+=('FAIL')
    _case_descriptions+=("${description}  (exit ${render_status})")
    return 0
  fi

  while :; do
    printf '    [y] pass  [n] fail  [s] skip  [q] quit → '
    if ! read -r answer; then
      answer="q"
    fi
    case "$answer" in
      y|Y|yes|Yes|"")
        _case_statuses+=('PASS')
        _case_descriptions+=("$description")
        return 0
        ;;
      n|N|no|No)
        _case_statuses+=('FAIL')
        _case_descriptions+=("$description")
        return 0
        ;;
      s|S|skip|Skip)
        _case_statuses+=('SKIP')
        _case_descriptions+=("$description")
        return 0
        ;;
      q|Q|quit|exit)
        printf '\n'
        _series_end
        _test_msg "Test stopped by user."
        exit 0
        ;;
      *)
        printf '    Unknown answer: %s\n' "$answer"
        ;;
    esac
  done
}