## Process one image

Set `input` to an image file and `output` to the destination PNG:

```bash
input="input.avif"
output="output.png"
size="5120x2880"
blur="12.0"

magick "$input" \
  -auto-orient \
  -filter Lanczos \
  -resize "${size}^" \
  -blur "0x${blur}" \
  -gravity center \
  -extent "$size" \
  "$output"
```

## Process every file in a directory

The input directory should contain supported image files. Results go to `outputs_png`, and the originals remain unchanged:

```bash
input_dir="inputs"
output_dir="outputs_png"
size="5120x2880"
blur="12.0"

mkdir -p "$output_dir"

magick mogrify \
  -path "$output_dir" \
  -format png \
  -auto-orient \
  -filter Lanczos \
  -resize "${size}^" \
  -blur "0x${blur}" \
  -gravity center \
  -extent "$size" \
  "$input_dir"/*
```

The reusable scripts in the repository's `script/` directory accept the same size and blur settings:

```bash
bash script/imagemagick/image-to-png.sh input.avif output.png [WIDTH [HEIGHT [BLUR]]]
bash script/imagemagick/images-to-png.sh inputs outputs_png [WIDTH [HEIGHT [BLUR]]]
```

