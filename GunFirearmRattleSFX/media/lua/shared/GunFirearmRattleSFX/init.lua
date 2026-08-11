local Compatibility = require("GunFirearmRattleSFX/Compatibility")
GunFirearmRattleSFX = GunFirearmRattleSFX or {}
GunFirearmRattleSFX.VERSION = "0.1.0"
GunFirearmRattleSFX.register = Compatibility.register
GunFirearmRattleSFX.RegisterItem = Compatibility.register
GunFirearmRattleSFX.diagnose = function(snapshot)
    return Compatibility.diagnose(snapshot, require("GunFirearmRattleSFX/DecisionEngine"))
end
return GunFirearmRattleSFX
