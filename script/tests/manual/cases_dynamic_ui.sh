_select_minimal() {
  local choice="" status=0
  local -a options=(one two three)
  ui_select choice "Choose a package:" "" 0 minimal "${options[@]}" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _test_msg "  Selected: index ${choice} → ${options["$choice"]}"
}

_select_default() {
  local choice="" status=0
  local -a options=(one two three)
  ui_select choice "Choose a package:" "" 1 default "${options[@]}" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _test_msg "  Selected: index ${choice} → ${options["$choice"]}"
}

_select_detail() {
  local choice="" status=0
  local -a options=(one two three)
  ui_select choice "Choose a package:" $'Details\n  Additional packages will be installed' 0 minimal "${options[@]}" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _test_msg "  Selected: index ${choice} → ${options["$choice"]}"
}

_select_many() {
  local choice="" status=0
  local -a options=()
  local i
  for ((i = 0; i < 40; i++)); do
    options+=("Package ${i}")
  done
  ui_select choice "Pick one of forty:" "" 0 minimal "${options[@]}" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _test_msg "  Selected: index ${choice} → ${options["$choice"]}"
}

_select_single() {
  local choice="" status=0
  local -a options=("only option")
  ui_select choice "Pick the single option:" "" 0 minimal "${options[@]}" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _test_msg "  Selected: index ${choice} → ${options["$choice"]}"
}

_select_special() {
  local choice="" status=0
  local -a options=(
    "Package with spaces & ampersands"
    "Unicode äöü × ⇒"
    "plain"
  )
  ui_select choice "Which unusual option?" "" 0 minimal "${options[@]}" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _test_msg "  Selected: index ${choice} → ${options["$choice"]}"
}

_select_yesno() {
  local choice="" status=0
  ui_select choice "Install development tools? (1/3)" \
    $'Description\n  Essential toolchain and helpers' 0 minimal "Yes" "No" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  if ((choice == 0)); then
    _test_msg "  → Yes"
  else
    _test_msg "  → No"
  fi
}

_select_no_options() {
  local choice="" status=0
  ui_select choice "Prompt" "" 0 minimal || status=$?
  printf '\n'
  _test_msg "  Exit code with no options: ${status} (expected 2)"
}

run_ui_select() {
  _series_begin "ui_select" \
    "single-choice menu: navigation, default highlight, detail, many options"
  _case "Minimal style, 3 options (navigate with arrows, confirm with Enter)" \
    _select_minimal
  _case "Default style (separator), 3 options, default highlight at index 1" \
    _select_default
  _case "Detail text below the prompt, 3 options" \
    _select_detail
  _case "Yes/no questionnaire question: 2 options (Yes/No), Enter picks default = Yes" \
    _select_yesno
  _case "Many options (40): navigate across the whole list and past the edges" \
    _select_many
  _case "Single option" \
    _select_single
  _case "Long options and special characters" \
    _select_special
  _case "No options: must be rejected with exit code 2" \
    _select_no_options
  _series_end
}

_multiselect_done() {
  local -a items=("$@")
  local count=${#items[@]}
  local list=""
  if ((count > 0)); then
    printf -v list ' %s' "${items[@]}"
    list="${list# }"
  else
    list="none"
  fi
  _test_msg "  Selected ${count}: ${list}"
}

_multiselect_all() {
  local -a chosen=()
  local status=0
  ui_multiselect chosen "Select packages:" alpha beta gamma || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _multiselect_done "${chosen[@]}"
}

_multiselect_two() {
  local -a chosen=()
  local status=0
  ui_multiselect chosen "Select packages:" alpha beta gamma || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _multiselect_done "${chosen[@]}"
}

_multiselect_none() {
  local -a chosen=()
  local status=0
  ui_multiselect chosen "Select packages:" alpha beta gamma || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _multiselect_done "${chosen[@]}"
}

_multiselect_many() {
  local -a chosen=()
  local status=0
  local -a options=()
  local i
  for ((i = 0; i < 25; i++)); do
    options+=("pkg-${i}")
  done
  ui_multiselect chosen "Select packages:" "${options[@]}" || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _multiselect_done "${chosen[@]}"
}

_multiselect_duplicates() {
  local -a chosen=()
  local status=0
  ui_multiselect chosen "Select packages:" dup dup other || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _multiselect_done "${chosen[@]}"
}

_multiselect_no_options() {
  local -a chosen=()
  local status=0
  ui_multiselect chosen "Select packages:" || status=$?
  printf '\n'
  _test_msg "  Exit code with no packages: ${status} (expected 2)"
}

run_ui_multiselect() {
  _series_begin "ui_multiselect" \
    "checkbox list: Space toggle, All shortcut, count line, selection summary"
  _case "Press Space on All, then Enter: result must list every package and never include All" \
    _multiselect_all
  _case "Toggle two by hand: result must list exactly those two, count '2 items selected'" \
    _multiselect_two
  _case "Press Enter immediately: 'No items selected', result empty" \
    _multiselect_none
  _case "Many packages (25): browse, toggle several, check result ordering" \
    _multiselect_many
  _case "Duplicate names: each occurrence can be selected independently" \
    _multiselect_duplicates
  _case "No packages: must be rejected with exit code 2" \
    _multiselect_no_options
  _series_end
}

_grouped_rows=(
  'Dev tools'
  'go' 'nvm' 'rustup'
  'Media'
  'yt-dlp' 'ffmpeg'
)
_grouped_kinds=(g i i i g i i)

_grouped_choose() {
  local -a chosen=()
  local status=0
  ui_multiselect_grouped chosen "Select packages:" \
    _grouped_rows _grouped_kinds || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _multiselect_done "${chosen[@]}"
}

_multiselect_group_header() {
  _grouped_choose
}

_multiselect_group_toggle() {
  _grouped_choose
}

_multiselect_group_partial() {
  _grouped_choose
}

_multiselect_group_all() {
  _grouped_choose
}

_multiselect_group_mixed() {
  _grouped_choose
}

_multiselect_group_scroll() {
  _grouped_choose
}

_multiselect_group_real() {
  local -a chosen=()
  local status=0
  local -a rows=()
  local -a kinds=()
  if ! catalog_package_rows rows kinds homebrew_extended macos brew; then
    _test_msg "  catalog_package_rows failed"
    return 1
  fi
  ui_multiselect_grouped chosen "Select extra packages:" rows kinds || status=$?
  printf '\n'
  if ((status != 0)); then
    _test_msg "  Menu exited with code ${status}"
    return "$status"
  fi
  _multiselect_done "${chosen[@]}"
}

run_ui_multiselect_grouped() {
  _series_begin "ui_multiselect_grouped" \
    "grouped checkbox list: group headers, tri-state, All shortcut, real catalog"
  _case "Press Enter immediately: headers shown, no blank line before the first group, result empty" \
    _multiselect_group_header
  _case "Space on a group header: selects exactly that group, header shows [x], count matches" \
    _multiselect_group_toggle
  _case "Toggle one item inside a group: header shows [-], only that item selected" \
    _multiselect_group_partial
  _case "Space on All: every group and item shows [x], result lists every package; press Space on All again to clear" \
    _multiselect_group_all
  _case "All, then Space on one group header: only that group clears, others stay [x]" \
    _multiselect_group_mixed
  _case "Long grouped list: cursor moves across headers and items, blank line appears between groups" \
    _multiselect_group_scroll
  _case "Real catalog (homebrew_extended): four groups render with the production package names" \
    _multiselect_group_real
  _series_end
}