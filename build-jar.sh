#!/bin/sh
# Builds the patched services.jar for modfix from YOUR stock services.jar.
# Usage: ./build-jar.sh /path/to/stock/services.jar [output.jar]
#
# Pull the stock jar from the phone with the modfix module DISABLED,
# otherwise you will pull the already-patched one:
#   adb pull /system/framework/services.jar
#
# Needs: apktool, patch, zip, unzip
set -e

STOCK="$1"
OUT="${2:-$PWD/services_patched_final.jar}"
HERE="$(cd "$(dirname "$0")" && pwd)"
DIFF="$HERE/modfix/patches/AudioService-modservice-routing.diff"

[ -f "$STOCK" ] || { echo "usage: $0 /path/to/stock/services.jar [output.jar]"; exit 1; }
for t in apktool patch zip unzip; do
  command -v $t >/dev/null || { echo "missing tool: $t"; exit 1; }
done

# Make both paths absolute, because we cd around below
STOCK="$(cd "$(dirname "$STOCK")" && pwd)/$(basename "$STOCK")"
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 1. Decompile (no resources)
apktool d -r "$STOCK" -o "$WORK/svc"

# 2. Apply the smali diff (dry run first so a mismatch fails cleanly)
cd "$WORK/svc/smali"
patch -p1 --dry-run < "$DIFF" || { echo "Diff does not apply to this build. Line numbers or code differ."; exit 1; }
patch -p1 < "$DIFF"
cd "$WORK"

# 3. Rebuild
apktool b svc -o "$WORK/patched.jar"

# 4. Take only the dex files from the rebuilt jar and drop them into a copy of
#    the stock jar, uncompressed. The apktool output is missing resources
#    (like compat_config) that the stock jar has.
mkdir dex
(cd dex && unzip -o ../patched.jar 'classes*.dex')
cp "$STOCK" "$OUT"
(cd dex && zip -0 "$OUT" classes*.dex)

echo "Built $OUT"
echo "Next: ./package-modfix.sh $OUT"
