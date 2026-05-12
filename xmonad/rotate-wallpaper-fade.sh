#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="${1:-"$HOME/wallpapers"}"
frames="${WALLPAPER_FADE_FRAMES:-12}"
delay="${WALLPAPER_FADE_DELAY:-0.025}"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
lock_dir="$runtime_dir/rotate-wallpaper-fade.lock"

if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi

work_dir="$(mktemp -d "$runtime_dir/rotate-wallpaper-fade.XXXXXX")"
cleanup() {
  rm -rf "$work_dir" "$lock_dir"
}
trap cleanup EXIT INT TERM

next_wallpaper="$(
  find "$wallpaper_dir" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -print0 | shuf -z -n 1 | tr -d '\0'
)"

if [ -z "$next_wallpaper" ]; then
  exit 1
fi

screen_size="$(
  xdpyinfo | awk '/dimensions:/ { print $2 }'
)"

if [ -z "$screen_size" ]; then
  feh --bg-fill "$next_wallpaper"
  exit 0
fi

current="$work_dir/current.png"
target="$work_dir/target.png"

import -window root "$current"
magick "$next_wallpaper" -auto-orient -resize "${screen_size}^" -gravity center -extent "$screen_size" "$target"

for step in $(seq 1 "$frames"); do
  percent=$((step * 100 / frames))
  frame="$work_dir/frame-$step.png"
  magick "$current" "$target" -define "compose:args=$percent" -compose blend -composite "$frame"
  feh --bg-fill "$frame"
  sleep "$delay"
done

feh --bg-fill "$next_wallpaper"
