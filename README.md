# griffin-modfix

Fixes to get the JBL SoundBoost (and hopefully other audio Moto Mods) working on the Moto Z (griffin, XT1650) running LineageOS 18.1.

## What was broken

1. **Permission denied.** `com.motorola.modservice` is refused `MODIFY_AUDIO_ROUTING`, so it can't register the mod speaker with AudioService. The mod attaches but Android ignores it.
2. **No audio route.** The stock `mixer_paths.xml` has no `usb-headset` route, which is what the HAL selects for mod audio. The mod speaker routes (TERT_MI2S) are fully defined in the file but nothing points at them, so even a registered speaker stays silent.

## What's here

| Path | What it does |
|---|---|
| `modmix/` | Magisk module that remaps the `usb-headset` paths in `mixer_paths.xml` to the mod speaker paths |
| `modfix/` | Magisk module for the permission fix. Ships `module.prop`, `customize.sh` and a smali diff (see below) |
| `modfix/patches/AudioService-modservice-routing.diff` | Smali diff for `AudioService` that lets `com.motorola.modservice` through the routing permission check, and only that package |
| `build-jar.sh` | Builds the patched `services.jar` from your own stock jar |
| `package-modfix.sh`, `package-modmix.sh` | Pack the Magisk zips |
| `0001-griffin-health-pin-internal-battery.patch` | Source patch for the detach shutdown bug. **Untested, see Known issues** |

## Status

- Loud, clear JBL audio on boot-attach and live attach/detach
- Pause/resume behaves like a normal wired device
- Tested on: LineageOS `18.1-20240306-NIGHTLY-griffin` (`lineage_griffin-userdebug 11 RQ3A.211001.001`)

## Install

Both modules need Magisk v20.4 or newer. Install modmix and modfix, then reboot.

**modmix:** run `./package-modmix.sh`, then flash `modmix-griffin.zip` from the Magisk app.

**modfix** is not a drop-in zip. It needs a patched `services.jar`, and that jar is specific to your exact Lineage build, so it isn't distributed here. You build it from your own phone's jar (see below), then package it into a Magisk zip.

Use a build matching the one above. A modified `services.jar` on a different build can bootloop. The module's `customize.sh` refuses to install on any other `ro.lineage.version`.

## Building the modfix jar

You need a Linux box with `apktool`, `patch`, `zip`, `unzip` and `adb`.

1. Pull the stock jar from the phone. Disable the modfix module first if it's already installed, otherwise you'll pull the patched one:
   `adb pull /system/framework/services.jar`
2. Build the patched jar:
   `./build-jar.sh services.jar`
3. Package the Magisk zip:
   `./package-modfix.sh services_patched_final.jar`
4. Flash `modfix-griffin.zip` in the Magisk app and reboot.

What `build-jar.sh` does: decompiles `services.jar` with `apktool d -r`, applies `modfix/patches/AudioService-modservice-routing.diff` to `AudioService.smali`, rebuilds with `apktool b`, then copies only the rebuilt `classes*.dex` files (stored uncompressed with `zip -0`) into a copy of the stock jar. The apktool output alone is missing resources the stock jar has, so don't use it directly. If the diff doesn't apply, your build differs from the tested one.

The install script also creates empty whiteout files for `services.art/.odex/.vdex`, so Android loads the patched jar instead of the stale precompiled code.

## Removal and rollback

- Boot into safe mode (hold volume down during the boot animation) to disable all Magisk modules
- Or from recovery or adb: `touch /data/adb/modules/modfix/disable` (same for `modmix`), then reboot
- Or delete the module folder from `/data/adb/modules/`

## Known issues

- **Shutdown on detach.** If you boot with the JBL attached, the health HAL can latch onto the mod's battery (`gb_battery`) as the primary battery instead of the phone's own cell. Detaching the mod in that state triggers `shutdown,battery`. Attaching the mod after boot is fine, and both batteries report correctly.
- The health patch pins the battery paths to `/sys/class/power_supply/battery/*` in the griffin device tree's `HealthService.cpp`. It is written but has **not been built or tested on a device yet**. It is included for reference, not as a verified fix.
- Until then, workaround: attach the mod after the phone has booted, or power off before removing it.
- Other Moto Z variants (nash, addison, albus, sheridan) are untested.
- The third party JBL SoundBoost2 companion app crashes on Android 11 because of library visibility restrictions.

## Goal

Get these fixes properly upstreamed to LineageOS so nobody has to run Magisk hacks for this. The health patch will go to Gerrit once it's built and tested.

## Not included

No proprietary files, no device specific logo or bootanimation dumps, no prebuilt or patched `services.jar`.
