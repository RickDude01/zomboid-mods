local Adapter = require("GunFirearmRattleSFX/Adapter")
Events.OnPlayerUpdate.Add(function(player)
    if player and player:isLocalPlayer() then Adapter.tick(player) end
end)
for _, eventName in ipairs({ "OnEquipPrimary", "OnEquipSecondary", "OnClothingUpdated" }) do
    local event = Events[eventName]
    if event and event.Add then event.Add(function() Adapter.invalidateEquipment() end) end
end
