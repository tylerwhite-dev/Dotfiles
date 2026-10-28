#!/usr/bin/env bash

ui_color_reset=""
ui_color_heading=""
ui_color_question=""
ui_color_success=""
ui_color_error=""
ui_color_hint=""
ui_color_comment=""
ui_color_selected=""
ui_color_package=""
ui_color_group=""

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  ui_color_reset=$'\033[0m'
  ui_color_heading=$'\033[1;34m'
  ui_color_question=$'\033[1;33m'
  ui_color_success=$'\033[1;32m'
  ui_color_error=$'\033[1;31m'
  ui_color_hint=$'\033[2m'
  ui_color_comment=$'\033[0;33m'
  ui_color_selected=$'\033[1;34m'
  ui_color_package=$'\033[90m'
  ui_color_group=$'\033[1;2m'
fi

ui_timeline_frames=('◎' '◉' '●' '◉' '◎' '○')
# ui_timeline_frames=('◌' '○' '◎' '◉' '●' '◉' '◎' '○')
ui_timeline_frame_microseconds=125000
