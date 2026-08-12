# Compatibility guide

Automatic classification accepts Build 42 firearm metadata and conservative legacy combinations: ranged status plus ammunition and at least one reload/firearm signal. Bows, crossbows, slingshots, and other ranged weapons are excluded. Ambiguous tagged firearms fall back to long gun for two-handed or heavy items, otherwise handgun.

Only the local player's held or visibly attached items qualify. Inventory contents, firing, reloading, drawing, holstering, and weapon parts do not affect this effect.

Use the stable exact-item API when a mod's metadata is incomplete. `registerItem` and
the values shown below are stable and additive from version 0.1.0 onward:

```lua
local GunFirearmRattleSFX = require("GunFirearmRattleSFX/init")
GunFirearmRattleSFX.registerItem("Namespace.Item", "handgun")
GunFirearmRattleSFX.registerItem("Namespace.Rifle", "longgun")
GunFirearmRattleSFX.registerItem("Namespace.Prop", "silent")
```

Accepted classifications are `handgun`, `longgun`, and `silent`. Registrations are
exact full item IDs, always override automatic classification, and use last-write-wins
when registered more than once. Invalid calls return `false` and emit a deduplicated
warning without interrupting loading.

For an opt-in compatibility report in the Lua/debug console, call:

```lua
GunFirearmRattleSFX.debugCurrent()
```

The report includes qualifying held and attached items, classification evidence,
selected profile and carry state, settings, and the active suppression reason.

`Base.Pistolm93r` from Vanilla Weapons Plus – Gunworks Edition is an optional smoke
test fixture. The mod does not declare it as a dependency.
