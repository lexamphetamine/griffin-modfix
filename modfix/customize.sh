#!/system/bin/sh
# modfix install-time script (Magisk runs this from the module zip)

REQUIRED="18.1-20240306-NIGHTLY-griffin"

[ "$(getprop ro.lineage.version)" = "$REQUIRED" ] || abort "This module is built for $REQUIRED only. Aborting so your phone doesn't bootloop."

[ -f "$MODPATH/system/framework/services.jar" ] || abort "services.jar is missing from the module. See the README for how to build it."

# Hide the precompiled oat files so the patched services.jar is actually used
OAT="$MODPATH/system/framework/oat/arm64"
mkdir -p "$OAT"
for e in art odex vdex; do
  mknod "$OAT/services.$e" c 0 0
done

set_perm "$MODPATH/system/framework/services.jar" 0 0 0644
