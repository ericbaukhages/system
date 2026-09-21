# Image Manipulation with ImageMagick

Use this skill when you need to process or manipulate images on a Linux or macOS system using ImageMagick's `magick` CLI.

## When to use

- Resize single images or batches of images.
- Convert between image formats.
- Create thumbnails.
- Retrieve image dimensions and metadata.
- Batch-process wallpapers or photos with specific criteria.

## Prerequisites

- ImageMagick installed and `magick` available on PATH.
- Bash shell.

## Examples

### Check that ImageMagick is installed

```bash
command -v magick &> /dev/null || { echo "ImageMagick required"; exit 1; }
```

### Get image dimensions

```bash
# Single image
magick identify -format "%wx%h" path/to/image.jpg

# Multiple images
for img in path/to/images/*; do
  magick identify -format "%f: %wx%h\n" "$img"
done
```

### Resize images

```bash
# Single image
magick input.jpg -resize 427x240 output.jpg

# Batch resize
for img in path/to/images/*; do
  filename=$(basename "$img")
  magick "$img" -resize 427x240 "path/to/output/thumb_$filename"
done
```

### Get detailed image information

```bash
magick identify -verbose path/to/image.jpg
```

### Process images based on dimensions

```bash
for img in path/to/images/*; do
  dimensions=$(magick identify -format "%w,%h" "$img")
  if [[ -n "$dimensions" ]]; then
    width=$(echo "$dimensions" | cut -d',' -f1)
    height=$(echo "$dimensions" | cut -d',' -f2)
    if [[ "$width" -eq 2560 || "$height" -eq 1440 ]]; then
      filename=$(basename "$img")
      echo "Processing $filename"
      magick "$img" -resize 427x240 "path/to/output/thumb_$filename"
    fi
  fi
done
```

## Guidelines

1. Always quote file paths that might contain spaces.
2. Loop over files with `for ...; do ...; done`.
3. Verify dimensions before processing to avoid unnecessary operations.
4. Use `!` after dimensions to force exact sizes, or `^` for minimum dimensions.
5. On older ImageMagick 6.x systems, the legacy `convert` command may be needed instead of `magick`.

## Common patterns

- Check installation: `command -v magick &> /dev/null`
- Get dimensions: `dimensions=$(magick identify -format "%w,%h" "$img")`
- Extract width/height: `width=$(echo "$dimensions" | cut -d',' -f1)` and `height=$(echo "$dimensions" | cut -d',' -f2)`
- Conditional resize: `if [[ "$width" -gt 1920 ]]; then magick "$img" -resize 1920x1080 "$outputPath"; fi`
- Thumbnail: `filename=$(basename "$img"); magick "$img" -resize 427x240 "thumbnails/thumb_$filename"`

## Limitations

- Large batch operations can be memory-intensive.
- Some complex operations require additional ImageMagick delegates.

---

Adapted from GitHub's [awesome-copilot](https://github.com/github/awesome-copilot) skill "[Image Manipulation with ImageMagick](https://github.com/github/awesome-copilot/blob/main/skills/image-manipulation-image-magick/SKILL.md)".
