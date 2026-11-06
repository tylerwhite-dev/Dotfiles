#!/usr/bin/env bash
# Related command: ../../guide/imagemagic/README.md, "Process one image".
set -euo pipefail

usage() {
  printf 'Usage: %s INPUT OUTPUT.png [WIDTH [HEIGHT [BLUR]]]\n' "${0##*/}" >&2
  printf 'Defaults: WIDTH=5120 HEIGHT=2880 BLUR=12.0\n' >&2
}

if (( $# < 2 || $# > 5 )); then
  usage
  exit 2
fi

input=$1
output=$2
width=${3:-5120}
height=${4:-2880}
blur=${5:-12.0}

if [[ ! -f $input ]]; then
  printf 'Input file not found: %s\n' "$input" >&2
  exit 1
fi
if ! command -v magick >/dev/null 2>&1; then
  printf 'ImageMagick 7 (magick) is required.\n' >&2
  exit 127
fi

mkdir -p -- "$(dirname -- "$output")"
size="${width}x${height}"

magick "$input" \
  -auto-orient \
  -filter Lanczos \
  -resize "${size}^" \
  -blur "0x${blur}" \
  -gravity center \
  -extent "$size" \
  -depth 8 \
  "$output"
