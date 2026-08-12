package.path = "media/lua/shared/?.lua;media/lua/client/?.lua;" .. package.path

CharacterTrait = { DEAF = "deaf", HARD_OF_HEARING = "hardOfHearing" }

local Adapter = require("GunFirearmRattleSFX/Adapter")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getPrimaryHandItem = function() return nil end,
    getSecondaryHandItem = function() return nil end,
    isMoving = function() return true end,
    isAiming = function() return false end,
    isSeatedInVehicle = function() return false end,
    hasTrait = function(_, trait) return trait == CharacterTrait.DEAF end,
}

assertEqual(player.HasTrait, nil, "Build 42 exposes hasTrait, not HasTrait")
assertEqual(Adapter.snapshot(player).hearing, "Deaf")

local pistol = {
    getFullType = function() return "Base.Pistol" end,
    getAmmoType = function() return "Base.Bullets9mm" end,
    getMagazineType = function() return "Base.9mmClip" end,
    isTwoHandWeapon = function() return false end,
    isRanged = function() return true end,
    getActualWeight = function() return 1 end,
    isReloadable = function(_, argument)
        assertEqual(argument, "required", "Build 42's isReloadable requires an argument")
        return true
    end,
}
player.getPrimaryHandItem = function() return pistol end
Adapter.invalidateEquipment()
local snapshot = Adapter.snapshot(player)
assertEqual(snapshot.selected.profile, "handgun", "pistol remains detectable without isReloadable")

local positionX = 0
local movementPlayer = {
    getX = function() return positionX end,
    getY = function() return 0 end,
    getPrimaryHandItem = function() return pistol end,
    getSecondaryHandItem = function() return nil end,
    isMoving = function() return false end,
    isAiming = function() return false end,
    isSeatedInVehicle = function() return false end,
    hasTrait = function() return false end,
}
Adapter.state.lastX, Adapter.state.lastY = nil, nil
Adapter.invalidateEquipment()
Adapter.snapshot(movementPlayer)
positionX = 0.75
assertEqual(Adapter.snapshot(movementPlayer).movement, "walk",
    "position movement must override Build 42's false isMoving result")

local originalSnapshot, originalPrint = Adapter.snapshot, print
local requestedSound, requestedGain, debugMessages = nil, nil, {}
Adapter.state.lastDebugDecision = nil
Adapter.snapshot = function()
    return { movement = "idle", distance = 0, settings = { enabled = true, volume = 50, frequency = "Very High" },
        selected = { profile = "handgun", carry = "held" }, random = function() return 0 end }
end
print = function(message) table.insert(debugMessages, message) end
local suppressed = Adapter.tick({ playSoundLocal = function() error("idle movement must not request playback") end })
assertEqual(suppressed.play, false, "idle movement should be suppressed")
assertEqual(debugMessages[1], "[GunFirearmRattleSFX DEBUG-DECISION] suppressed reason=idle",
    "adapter logs why playback was suppressed")
Adapter.snapshot = function()
    return { movement = "walk", distance = 1, settings = { enabled = true, volume = 50, frequency = "Very High" },
        selected = { profile = "handgun", carry = "held" }, random = function() return 0 end }
end
local result = Adapter.tick({
    playSoundLocal = function(_, sound, ...)
        assertEqual(select("#", ...), 0, "Build 42 playSoundLocal accepts only the sound name")
        requestedSound = sound
    end,
})
print, Adapter.snapshot = originalPrint, originalSnapshot
assertEqual(result.play, true, "eligible firearm movement should request playback")
assertEqual(requestedSound, "GunFirearmRattleSFX_Handgun01", "adapter requests the selected sound")
assertEqual(debugMessages[2], "[GunFirearmRattleSFX DEBUG-PLAY] requesting sound=GunFirearmRattleSFX_Handgun01 gain=0.129 profile=handgun carry=held",
    "adapter logs the exact playback request")
print("adapter_test: passed")
