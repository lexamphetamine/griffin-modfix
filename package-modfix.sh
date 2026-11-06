#!/bin/sh
# Packs the modfix Magisk module zip on your build machine.
# Usage: ./package-modfix.sh /path/to/patched/services.jar
set -e

JAR="$1"
[ -f "$JAR" ] || { echo "usage: $0 /path/to/patched/services.jar"; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/modfix-griffin.zip"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/system/framework" "$TMP/META-INF/com/google/android"
cp "$HERE/modfix/module.prop" "$TMP/module.prop"
cp "$HERE/modfix/customize.sh" "$TMP/customize.sh"
cp "$JAR" "$TMP/system/framework/services.jar"
cp "$HERE/installer/update-binary" "$HERE/installer/updater-script" "$TMP/META-INF/com/google/android/"

rm -f "$OUT"
(cd "$TMP" && zip -r "$OUT" .)
echo "Built $OUT"
