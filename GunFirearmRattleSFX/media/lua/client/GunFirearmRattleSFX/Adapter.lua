local Engine = require("GunFirearmRattleSFX/DecisionEngine")
local Compatibility = require("GunFirearmRattleSFX/Compatibility")
local Adapter = { state = { lastX = nil, lastY = nil, missedSteps = 0, cadenceDistance = 0,
    lastSample = nil, activeUntil = 0, equipmentAt = -math.huge, equipmentVersion = -1,
    held = {}, attached = {}, selected = nil, primaryHand = nil, secondaryHand = nil } }
local function setting(name, fallback)
    if GunFirearmRattleSFXModOptions and GunFirearmRattleSFXModOptions.getOption then
        local option = GunFirearmRattleSFXModOptions:getOption(name)
        if option and option.getValue then return option:getValue() end
    end
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.get then
        local ok, options = pcall(PZAPI.ModOptions.get, PZAPI.ModOptions, "GunFirearmRattleSFX")
        if ok and options and options.getOption then
            local option = options:getOption(name)
            if option and option.getValue then return option:getValue() end
        end
    end
    if GunFirearmRattleSFXOptions and GunFirearmRattleSFXOptions[name] ~= nil then return GunFirearmRattleSFXOptions[name] end
    return fallback
end
local function optionalTrue(item, method)
    return item[method] and item[method](item) == true
end
local function itemData(item)
    if not item then return nil end
    local fullType
    local ok, data = pcall(function()
        fullType = item:getFullType()
        local lowerType = string.lower(fullType or "")
        local nonFirearm = optionalTrue(item, "isBow") or optionalTrue(item, "isCrossbow")
            or optionalTrue(item, "isSlingshot") or string.find(lowerType, "bow", 1, true) ~= nil
            or string.find(lowerType, "slingshot", 1, true) ~= nil
        local ammunition = item.getAmmoType and item:getAmmoType() or nil
        local twoHanded = item.isTwoHandWeapon and item:isTwoHandWeapon() == true or false
        local explicitFirearm = item.isFirearm and item:isFirearm() == true
        local reloadable = item.isReloadable and item:isReloadable() == true
            or item.getReloadTime ~= nil or item.getMagazineType ~= nil
        local ranged = item.isRanged and item:isRanged() == true
        local weight = item.getActualWeight and item:getActualWeight() or 0
        return { fullType = fullType, nonFirearmRanged = nonFirearm,
            firearm = not nonFirearm and (explicitFirearm or (ranged and ammunition ~= nil and reloadable)),
            isFirearm = explicitFirearm, legacy = not explicitFirearm and ranged and ammunition ~= nil and reloadable,
            ranged = ranged, ammunition = ammunition ~= nil, reloadable = reloadable,
            handgun = not twoHanded and (tonumber(weight) or 0) < 2.5, twoHanded = twoHanded,
            weight = weight }
    end)
    if not ok and type(fullType) == "string" then Compatibility.warnMalformed(fullType) end
    return ok and data or nil
end
local function callsTrue(object, method)
    return object and object[method] and object[method](object) == true
end
local function isMoving(player, distance)
    if player.isMoving then return player:isMoving() end
    return distance > 0
end
local function movementState(player, distance)
    if not isMoving(player, distance) then return "idle" end
    if callsTrue(player, "isSneaking") then return "crouch" end
    if callsTrue(player, "isInjured") or callsTrue(player, "isPainful") then return "injured" end
    if callsTrue(player, "isSprinting") then return "sprint" end
    if callsTrue(player, "isRunning") then return "jog" end
    return "walk"
end
local function refreshEquipment(player, now)
    local held, attached = {}, {}
    for _, hand in ipairs({ player:getPrimaryHandItem(), player:getSecondaryHandItem() }) do
        local data = itemData(hand); if data then table.insert(held, data) end
    end
    if player.getAttachedItems then
        local ok, worn = pcall(player.getAttachedItems, player)
        if ok and worn and worn.size and worn.get then
            local sizeOk, size = pcall(worn.size, worn)
            if sizeOk and type(size) == "number" then
                for index = 0, size - 1 do
                    local entryOk, entry = pcall(worn.get, worn, index)
                    local attachedItem = entryOk and entry and entry.getItem and entry:getItem() or nil
                    local data = itemData(attachedItem)
                    if data then table.insert(attached, data) end
                end
            end
        end
    end
    Adapter.state.held, Adapter.state.attached = held, attached
    Adapter.state.selected = Engine.select({ held = held, attached = attached },
        Compatibility.overrides, Compatibility.warnOnce)
    Adapter.state.equipmentAt, Adapter.state.equipmentVersion = now, Compatibility.version
end

function Adapter.invalidateEquipment()
    Adapter.state.equipmentAt = -math.huge
end

function Adapter.snapshot(player)
    if not player then
        return { held = {}, attached = {}, settings = { enabled = true, volume = 50, frequency = "Normal" },
            movement = "idle", distance = 0, selected = nil }
    end
    local x, y = player:getX(), player:getY()
    local distance = Adapter.state.lastX and math.sqrt((x - Adapter.state.lastX)^2 + (y - Adapter.state.lastY)^2) or 0
    local movementJump = distance > 4.0
    Adapter.state.lastX, Adapter.state.lastY = x, y
    local held, attached = Adapter.state.held, Adapter.state.attached
    local now = getTimestampMs and getTimestampMs() or 0
    local primaryHand, secondaryHand = player:getPrimaryHandItem(), player:getSecondaryHandItem()
    if primaryHand ~= Adapter.state.primaryHand or secondaryHand ~= Adapter.state.secondaryHand then
        Adapter.state.primaryHand, Adapter.state.secondaryHand = primaryHand, secondaryHand
        Adapter.invalidateEquipment()
    end
    if now - Adapter.state.equipmentAt >= 250 or Adapter.state.equipmentVersion ~= Compatibility.version then
        refreshEquipment(player, now)
        held, attached = Adapter.state.held, Adapter.state.attached
    end
    local alternateLocomotion = callsTrue(player, "isDraggingCorpse")
        or callsTrue(player, "isCarryingAnimal") or callsTrue(player, "isCarryingHeavyItem")
    return { held = held, attached = attached, distance = distance, movementJump = movementJump,
        movement = movementState(player, distance),
        aiming = player:isAiming(), inVehicle = player:isSeatedInVehicle(),
        specialAction = callsTrue(player, "isVaulting") or callsTrue(player, "isClimbing")
            or callsTrue(player, "isFalling") or callsTrue(player, "isGettingUp"),
        alternateLocomotion = alternateLocomotion,
        hearing = player:HasTrait("Deaf") and "Deaf" or (player:HasTrait("HardOfHearing") and "Hard of Hearing" or nil),
        settings = { enabled = setting("enabled", true), volume = setting("volume", 50), frequency = setting("frequency", "Normal") },
        overrides = Compatibility.overrides, missedSteps = Adapter.state.missedSteps,
        cadenceDistance = Adapter.state.cadenceDistance, lastSample = Adapter.state.lastSample,
        selected = Adapter.state.selected,
        activePlayback = getTimestampMs and getTimestampMs() < Adapter.state.activeUntil,
        warn = Compatibility.warnOnce, random = function() return ZombRandFloat(0, 1) end }
end
function Adapter.diagnose(player)
    local snapshot = Adapter.snapshot(player)
    return Compatibility.diagnose(snapshot, Engine)
end
function Adapter.tick(player)
    if not player then return end
    local result = Engine.decide(Adapter.snapshot(player)); Adapter.state.missedSteps = result.missedSteps or 0
    Adapter.state.cadenceDistance = result.cadenceDistance or 0
    if not result.play then return result end
    Adapter.state.lastSample = result.sample
    Adapter.state.activeUntil = (getTimestampMs and getTimestampMs() or 0) + 350
    player:playSoundLocal("GunFirearmRattleSFX_" .. result.sample, result.gain)
    return result
end
return Adapter
