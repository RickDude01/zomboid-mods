local Engine = require("GunFirearmRattleSFX/DecisionEngine")
local Compatibility = require("GunFirearmRattleSFX/Compatibility")
local Adapter = { state = { lastX = nil, lastY = nil, missedSteps = 0, lastSample = nil, activeUntil = 0 } }
local function setting(name, fallback)
    if GunFirearmRattleSFXOptions and GunFirearmRattleSFXOptions[name] ~= nil then return GunFirearmRattleSFXOptions[name] end
    return fallback
end
local function itemData(item)
    if not item then return nil end
    local ammunition = item.getAmmoType and item:getAmmoType() or nil
    return { fullType = item:getFullType(), firearm = item:isRanged() and ammunition ~= nil, ammunition = ammunition ~= nil,
        handgun = not item:isTwoHandWeapon(),
        twoHanded = item:isTwoHandWeapon(), weight = item:getActualWeight() }
end
local function snapshot(player)
    local x, y = player:getX(), player:getY()
    local distance = Adapter.state.lastX and math.sqrt((x - Adapter.state.lastX)^2 + (y - Adapter.state.lastY)^2) or 0
    Adapter.state.lastX, Adapter.state.lastY = x, y
    local held = {}
    for _, hand in ipairs({ player:getPrimaryHandItem(), player:getSecondaryHandItem() }) do
        local data = itemData(hand); if data then table.insert(held, data) end
    end
    local attached = {}
    if player.getAttachedItems then
        local worn = player:getAttachedItems()
        for index = 0, worn:size() - 1 do
            local data = itemData(worn:get(index):getItem())
            if data then table.insert(attached, data) end
        end
    end
    return { held = held, attached = attached, distance = distance,
        movement = player:isSneaking() and "crouch" or (player:isSprinting() and "sprint" or (player:isRunning() and "jog" or "walk")),
        aiming = player:isAiming(), inVehicle = player:isSeatedInVehicle(),
        hearing = player:HasTrait("Deaf") and "Deaf" or (player:HasTrait("HardOfHearing") and "Hard of Hearing" or nil),
        settings = { enabled = setting("enabled", true), volume = setting("volume", 50), frequency = setting("frequency", "Normal") },
        overrides = Compatibility.overrides, missedSteps = Adapter.state.missedSteps, lastSample = Adapter.state.lastSample,
        activePlayback = getTimestampMs and getTimestampMs() < Adapter.state.activeUntil, random = function() return ZombRandFloat(0, 1) end }
end
function Adapter.tick(player)
    if not player then return end
    local result = Engine.decide(snapshot(player)); Adapter.state.missedSteps = result.missedSteps or 0
    if not result.play then return result end
    Adapter.state.lastSample = result.sample
    Adapter.state.activeUntil = (getTimestampMs and getTimestampMs() or 0) + 350
    player:playSoundLocal("GunFirearmRattleSFX_" .. result.sample)
    return result
end
return Adapter
