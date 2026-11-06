#!/bin/sh
# Packs the modmix Magisk module zip (the mixer_paths.xml remap).
# Usage: ./package-modmix.sh
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/modmix-griffin.zip"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/META-INF/com/google/android"
cp -r "$HERE/modmix/." "$TMP/"
cp "$HERE/installer/update-binary" "$HERE/installer/updater-script" "$TMP/META-INF/com/google/android/"

rm -f "$OUT"
(cd "$TMP" && zip -r "$OUT" .)
echo "Built $OUT"
