run_ui_stage() {
  _series_begin "ui_stage" \
    "heading + separator + metadata; empty and long values"
  _case "Normal: title and metadata" \
    ui_stage "SYSTEM SETUP" "fedora · 8 procedures available"
  _case "Empty title, metadata only" \
    ui_stage "" "metadata-only"
  _case "Long title (> terminal width): wrap must not break separator" \
    ui_stage "This is a long stage heading that clearly exceeds typical terminal width and keeps stretching further" \
    "very long metadata string too"
  _case "Empty metadata" \
    ui_stage "SYSTEM SETUP" ""
  _case "Special characters and Cyrillic in title" \
    ui_stage "Настройка • системы <v1.0>? & (тест)" "arch · 3 procedures"
  _series_end
}

run_ui_summary_item() {
  _series_begin "ui_summary_item" \
    "summary row: ●/○ symbol, color, yes/no label"
  _case "selected=yes: green ● + yes_label" \
    ui_summary_item "Install packages" yes yes no
  _case "selected=no: dim ○ + no_label (red)" \
    ui_summary_item "Change default shell" no yes no
  _case "Custom yes/no_labels" \
    ui_summary_item "Install packages" yes "Установить" "Пропустить"
  _case "Empty label when selected=no" \
    ui_summary_item "" no yes no
  _case "Long label: line wrap behavior" \
    ui_summary_item "A long procedure label exceeding line width to check how summary wraps" yes installed skipped
  _case "Empty yes_label when selected=yes" \
    ui_summary_item "Install packages" yes "" "not selected"
  _series_end
}

run_ui_summary_item_packages() {
  _series_begin "ui_summary_item_packages" \
    "package summary row: count >0 vs =0, status"
  _case "count>0: green ● + colored status" \
    ui_summary_item_packages "Optional brew packages" 5 "5 selected"
  _case "count=0: dim ○ + plain status" \
    ui_summary_item_packages "Optional brew packages" 0 "no packages selected"
  _case "count=1: single unit" \
    ui_summary_item_packages "Optional brew packages" 1 "1 selected"
  _case "Large count (42)" \
    ui_summary_item_packages "Optional brew packages" 42 "42 selected"
  _case "Empty status when count>0" \
    ui_summary_item_packages "Optional brew packages" 3 ""
  _case "Negative count" \
    ui_summary_item_packages "Optional brew packages" -2 "negative count"
  _series_end
}

_tsa_col60() {
  local saved="${COLUMNS:-}"
  COLUMNS=60
  ui_timeline_active 1 8 \
    "Install essential development toolchain packages and helpers" 45 '◉' yes
  printf '\n'
  COLUMNS="$saved"
}

_tsa_col40() {
  local saved="${COLUMNS:-}"
  COLUMNS=40
  ui_timeline_active 1 8 \
    "Install essential development toolchain packages and helpers" 45 '◉' yes
  printf '\n'
  COLUMNS="$saved"
}

_tsa_animation() {
  local i marker
  for ((i = 0; i < 20; i++)); do
    ui_timeline_frame marker $((i * ui_timeline_frame_microseconds))
    ui_timeline_active 1 8 "Install packages" $((i / 4)) "$marker" yes
    sleep 0.125
  done
  printf '\n'
}

run_ui_timeline_active() {
  _series_begin "ui_timeline_active" \
    "marker + progress 01/08 + label + timer; truncation and time format"
  _case "Normal: 01/08, label, timer 00:45" \
    ui_timeline_active 1 8 "Install packages" 45 '◉' yes
  _case "Edge: current==total (08/08)" \
    ui_timeline_active 8 8 "Install packages" 45 '◉' yes
  _case "current>total (09/08): invalid data" \
    ui_timeline_active 9 8 "Install packages" 45 '◉' yes
  _case "Long label at COLUMNS=60 (limit 28 chars)" \
    _tsa_col60
  _case "Long label at COLUMNS=40 (minimum 20 chars)" \
    _tsa_col40
  _case "Timer with hours: 3661s → 01:01:01" \
    ui_timeline_active 1 8 "Install packages" 3661 '●' yes
  _case "Timer at 0s → 00:00" \
    ui_timeline_active 1 8 "Install packages" 0 '●' yes
  _case "Marker animation 20 frames (redraw=yes)" \
    _tsa_animation
  _series_end
}

run_ui_timeline_finished() {
  _series_begin "ui_timeline_finished" \
    "final row: ● success / × failure, label, duration"
  _case "Success (status=0): green ●, 135s → 2m 15s" \
    ui_timeline_finished 0 "git clone" 135
  _case "Failure (status=1): red ×, 45s → 45s" \
    ui_timeline_finished 1 "git clone" 45
  _case "Status 255: should render as failure" \
    ui_timeline_finished 255 "git clone" 45
  _case "Long label: width truncation" \
    ui_timeline_finished 0 "A very long procedure label that certainly exceeds truncation limit" 3661
  _case "Duration 0s → 0s" \
    ui_timeline_finished 0 "install" 0
  _case "Duration 3661s → 1h 01m 01s" \
    ui_timeline_finished 1 "install" 3661
  _case "Empty label" \
    ui_timeline_finished 0 "" 5
  _series_end
}

_tsout_cr() {
  ui_timeline_output $'progress 10%\rprogress 45%\rprogress 100%'
}

_tsout_ansi() {
  ui_timeline_output "$(printf '\033[1;31mred text\033[0m reset')"
}

run_ui_timeline_output() {
  _series_begin "ui_timeline_output" \
    "action output line (│ + text); trimming on last \\r"
  _case "Normal line" \
    ui_timeline_output "++ git clone https://github.com/example/repo --depth 1"
  _case "Line with \\r: only part after last \\r remains" \
    _tsout_cr
  _case "Long line" \
    ui_timeline_output "very long action output line that keeps going and going beyond terminal width border"
  _case "Empty line" \
    ui_timeline_output ""
  _case "Special characters and Cyrillic" \
    ui_timeline_output "Пакет с пробелами & <tags> | pipes, unicode áéîøü"
  _case "ANSI codes in line" \
    _tsout_ansi
  _series_end
}