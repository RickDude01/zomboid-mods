# Gun / Firearm Rattle SFX

Version 0.1.0 for Project Zomboid Build 42 (tested on 42.20.2).

This client-only mod adds restrained, intermittent movement Foley when the local survivor carries a recognized firearm. Handguns use a lighter profile; long guns use a heavier sling-and-hardware profile. It does not create world noise, attract zombies, synchronize state, or require server installation.

## Install

Copy the `GunFirearmRattleSFX` folder into the game's `Zomboid/mods` directory and enable it in the Mods menu.

## Settings

The intended Build 42 Mod Options controls are enabled (default on), volume (0–100, default 50), and frequency (Very Low, Low, Normal, High, Very High; default Normal). Settings are client-side and apply on the next eligible movement step.

Supported movement is grounded crouch-walk, walk, jog, sprint, and injured movement. Aiming, idle, vehicles, special actions, alternate locomotion, and inventory-only firearms are silent. Deaf suppresses playback; Hard of Hearing reduces it.

## Compatibility API

```lua
local GunFirearmRattleSFX = require("GunFirearmRattleSFX/init")
GunFirearmRattleSFX.register("MyMod.CustomRifle", "long gun")
GunFirearmRattleSFX.register("MyMod.CustomPistol", "handgun")
GunFirearmRattleSFX.register("MyMod.NoisyProp", "silent")
```

Valid registrations return `true`; invalid calls return `false` without throwing. Later registrations replace earlier ones and emit one warning.

See [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md), [docs/TEST-CHECKLIST.md](docs/TEST-CHECKLIST.md), and [docs/PROVENANCE.md](docs/PROVENANCE.md).
