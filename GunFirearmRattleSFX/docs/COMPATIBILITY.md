# Compatibility guide

Automatic classification accepts Build 42 firearm metadata and conservative legacy combinations: ranged status plus ammunition and at least one reload/firearm signal. Bows, crossbows, slingshots, and other ranged weapons are excluded. Ambiguous tagged firearms fall back to long gun for two-handed or heavy items, otherwise handgun.

Only the local player's held or visibly attached items qualify. Inventory contents, firing, reloading, drawing, holstering, and weapon parts do not affect this effect.

Use the stable exact-item API when a mod's metadata is incomplete:

```lua
require("GunFirearmRattleSFX/init").register("Namespace.Item", "handgun")
```

Accepted classifications are `handgun`, `long gun`, and `silent`.
