# Gun / Firearm Rattle SFX

Version 0.1.0 for Project Zomboid Build 42 (tested on 42.20.2).

This client-only mod adds restrained, intermittent movement Foley when the local survivor carries a recognized firearm. Handguns use a lighter profile; long guns use a heavier sling-and-hardware profile. It does not create world noise, attract zombies, synchronize state, or require server installation.

## Install

Copy the `GunFirearmRattleSFX` folder into the game's `Zomboid/mods` directory and enable it in the Mods menu.

## Settings

The intended Build 42 Mod Options controls are enabled (default on), volume (0–100, default 50), and frequency (Very Low, Low, Normal, High, Very High; default Normal). Settings are client-side and apply on the next eligible movement step.

Supported movement is grounded crouch-walk, walk, jog, sprint, and injured movement. Aiming, idle, vehicles, special actions, alternate locomotion, and inventory-only firearms are silent. Deaf suppresses playback; Hard of Hearing reduces it.

## Validation

From the mod directory, run `./tests/validate_assets.sh` to validate the eight OGG assets and execute the deterministic Foley decision tests. The validator requires `ffmpeg`, `ffprobe`, and `luajit`.

To build both release layouts, run `./tools/build-distributions.sh`. The generated
`dist/manual-install/GunFirearmRattleSFX` folder is the folder copied into
`Zomboid/mods`. The generated `dist/workshop/GunFirearmRattleSFX` folder is a
Workshop upload wrapper containing `mods/GunFirearmRattleSFX` and its unlisted
metadata. Run `./tests/validate_package.sh` to build the layouts and verify their
contents. Neither script uploads to Steam or changes Workshop visibility.

## Troubleshooting

- If the mod is missing from the Mods menu, confirm that `mod.info` is directly
  inside `Zomboid/mods/GunFirearmRattleSFX`, not one directory deeper.
- If no accents play, check that the mod is enabled, volume is above 0, and the
  character is moving with a recognized firearm held or visibly attached.
- Aiming, vehicles, special actions, alternate locomotion, idle movement, and
  inventory-only firearms are intentionally silent.
- Automatic recognition is conservative for third-party firearms. Use the exact
  item override API described in `docs/COMPATIBILITY.md` when metadata is incomplete.

## Test status

The release candidate is tested on macOS with Build 42.20.2. Windows and Linux
are expected but unverified. Multiplayer is designed to remain client-side and
is expected to work without server installation, but multiplayer is untested.
The in-game listening pass in `docs/TEST-CHECKLIST.md` remains a release-owner
check and is not replaced by automated validation.

## Compatibility API

```lua
local GunFirearmRattleSFX = require("GunFirearmRattleSFX/init")
GunFirearmRattleSFX.registerItem("MyMod.CustomRifle", "longgun")
GunFirearmRattleSFX.registerItem("MyMod.CustomPistol", "handgun")
GunFirearmRattleSFX.registerItem("MyMod.NoisyProp", "silent")
```

Valid registrations return `true`; invalid calls return `false` without throwing. Later registrations replace earlier ones and emit one warning.

See [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md), [docs/TEST-CHECKLIST.md](docs/TEST-CHECKLIST.md), and [docs/PROVENANCE.md](docs/PROVENANCE.md).
