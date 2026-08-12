local Compatibility = require("GunFirearmRattleSFX/Compatibility")
GunFirearmRattleSFX = GunFirearmRattleSFX or {}
GunFirearmRattleSFX.VERSION = "0.1.0"
GunFirearmRattleSFX.registerItem = Compatibility.registerItem
-- Compatibility aliases retained for integrations released during 0.1.0.
GunFirearmRattleSFX.register = Compatibility.registerItem
GunFirearmRattleSFX.RegisterItem = Compatibility.registerItem
GunFirearmRattleSFX.diagnose = function(snapshot)
    return Compatibility.diagnose(snapshot, require("GunFirearmRattleSFX/DecisionEngine"))
end
GunFirearmRattleSFX.debugCurrent = function()
    local Adapter = require("GunFirearmRattleSFX/Adapter")
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    return Adapter.diagnose(player)
end
return GunFirearmRattleSFX
