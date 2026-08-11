local Adapter = require("GunFirearmRattleSFX/Adapter")
Events.OnPlayerUpdate.Add(function(player)
    if player and player:isLocalPlayer() then Adapter.tick(player) end
end)
