#!/usr/bin/env bash
# Related command: ../../guide/imagemagic/README.md, "Process every file in a directory".
set -euo pipefail

usage() {
  printf 'Usage: %s INPUT_DIR OUTPUT_DIR [WIDTH [HEIGHT [BLUR]]]\n' "${0##*/}" >&2
  printf 'Defaults: WIDTH=5120 HEIGHT=2880 BLUR=12.0\n' >&2
}

if (( $# < 2 || $# > 5 )); then
  usage
  exit 2
fi

input_dir=$1
output_dir=$2
width=${3:-5120}
height=${4:-2880}
blur=${5:-12.0}

if [[ ! -d $input_dir ]]; then
  printf 'Input directory not found: %s\n' "$input_dir" >&2
  exit 1
fi
if ! command -v magick >/dev/null 2>&1; then
  printf 'ImageMagick 7 (magick) is required.\n' >&2
  exit 127
fi

mkdir -p -- "$output_dir"
size="${width}x${height}"
processed=0

for input in "$input_dir"/*; do
  [[ -f $input ]] || continue

  filename=${input##*/}
  magick "${input}[0]" \
    -auto-orient \
    -filter Lanczos \
    -resize "${size}^" \
    -blur "0x${blur}" \
    -gravity center \
    -extent "$size" \
    "$output_dir/${filename}.png"
  ((processed += 1))
done

if (( processed == 0 )); then
  printf 'No files found in input directory: %s\n' "$input_dir" >&2
  exit 1
fi

printf 'Created %d PNG file(s) in %s\n' "$processed" "$output_dir"
