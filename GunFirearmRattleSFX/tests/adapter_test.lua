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
print("adapter_test: passed")
