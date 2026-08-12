local Engine = {}

local frequency = {
    ["Very Low"] = { chance = 0.20, maxMisses = 8 },
    Low = { chance = 0.35, maxMisses = 5 },
    Normal = { chance = 0.50, maxMisses = 3 },
    High = { chance = 0.70, maxMisses = 2 },
    ["Very High"] = { chance = 0.90, maxMisses = 1 },
}
local frequencyValues = { "Very Low", "Low", "Normal", "High", "Very High" }

local movementGain = { crouch = 0.45, walk = 0.65, jog = 0.85, sprint = 1.0, injured = 0.55 }
-- These are movement-distance units, not update frames.  They intentionally
-- remain coarse because custom movement overhauls cannot expose vanilla steps.
local cadenceDistance = { crouch = 0.45, walk = 0.50, jog = 0.65, sprint = 0.80, injured = 0.75 }
local maximumPlausibleDelta = 4.0
local samples = { handgun = { "Handgun01", "Handgun02", "Handgun03", "Handgun04" }, longGun = { "LongGun01", "LongGun02", "LongGun03", "LongGun04" } }

local defaultSettings = { enabled = true, volume = 50, frequency = "Normal" }

local function normalizeSettings(settings)
    settings = settings or {}
    local volume = tonumber(settings.volume)
    if not volume then volume = defaultSettings.volume end
    volume = math.max(0, math.min(100, volume))
    local selectedFrequency = settings.frequency
    if type(selectedFrequency) == "number" then selectedFrequency = frequencyValues[selectedFrequency] end
    if not frequency[selectedFrequency] then selectedFrequency = defaultSettings.frequency end
    return { enabled = settings.enabled ~= false, volume = volume, frequency = selectedFrequency }
end

local function hasAny(item, keys)
    for _, key in ipairs(keys) do if item[key] then return true end end
    return false
end

local function isList(value)
    if type(value) ~= "table" then return false end
    for key in pairs(value) do return type(key) == "number" end
    return true
end

function Engine.classify(item, overrides, warn)
    if type(item) ~= "table" or type(item.fullType) ~= "string" then return nil end
    local override = overrides and overrides[item.fullType]
    if override == "silent" then return nil end
    if override == "handgun" or override == "longgun" or override == "long gun" then
        return { profile = (override == "longgun" or override == "long gun") and "longGun" or "handgun", evidence = "explicit override" }
    end
    if item.bow or item.crossbow or item.slingshot or item.nonFirearmRanged then return nil end
    local tagged = (item.firearm == true or item.isFirearm == true) and item.legacy ~= true
    local legacy = item.ranged and item.ammunition and hasAny(item, { "reloadable", "reloadTime", "firearmType", "magazineType" })
    if not tagged and not legacy then return nil end
    if item.longGun or item.longgun then
        return { profile = "longGun", evidence = tagged and "firearm metadata" or "legacy firearm signals" }
    end
    if item.handgun then return { profile = "handgun", evidence = tagged and "firearm metadata" or "legacy firearm signals" } end
    if item.twoHanded or (tonumber(item.weight) or 0) >= 2.5 then
        if warn then warn(item.fullType, "ambiguous firearm metadata; fallback classification used") end
        return { profile = "longGun", evidence = "fallback: heavy or two-handed" }
    end
    if warn then warn(item.fullType, "ambiguous firearm metadata; fallback classification used") end
    return { profile = "handgun", evidence = "fallback: light or one-handed" }
end

function Engine.select(equipment, overrides, warn)
    if type(equipment) ~= "table" then return nil end
    local best, bestPriority
    local function consider(item, carry)
        local result = Engine.classify(item, overrides, warn)
        if not result then return end
        local priority = (carry == "attached" and result.profile == "longGun" and 4)
            or (carry == "held" and result.profile == "longGun" and 3)
            or (carry == "attached" and 2) or 1
        local bestType = best and best.item and best.item.fullType
        if not best or priority > bestPriority or (priority == bestPriority and item.fullType < bestType) then
            best, bestPriority = { profile = result.profile, carry = carry, evidence = result.evidence, item = item }, priority
        end
    end
    if isList(equipment.attached) then
        for _, item in ipairs(equipment.attached) do consider(item, "attached") end
    end
    if isList(equipment.held) then
        for _, item in ipairs(equipment.held) do consider(item, "held") end
    end
    return best
end

local function randomValue(random)
    local value = random and random() or math.random()
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

function Engine.decide(snapshot)
    local movement = snapshot.movement
    local movementAliases = { ["crouch-walk"] = "crouch", walking = "walk", jogging = "jog", sprinting = "sprint" }
    movement = movementAliases[movement] or movement
    local settings = normalizeSettings(snapshot.settings)
    local function suppressed(reason)
        return { play = false, reason = reason, cadenceDistance = 0, missedSteps = 0 }
    end
    if not settings.enabled then return suppressed("disabled") end
    if snapshot.aiming then return suppressed("aiming") end
    if snapshot.inVehicle or snapshot.vehicle then return suppressed("vehicle") end
    if snapshot.specialAction or snapshot.vaulting or snapshot.climbing or snapshot.falling or snapshot.gettingUp then
        return suppressed("special action")
    end
    if snapshot.alternateLocomotion or snapshot.draggingCorpse or snapshot.carryingLargeAnimal or snapshot.carryingHeavyObject then
        return suppressed("alternate locomotion")
    end
    if snapshot.equipping or snapshot.drawing or snapshot.attaching or snapshot.detaching or snapshot.holstering then
        return suppressed("weapon handling")
    end
    if snapshot.hearing == "Deaf" then return suppressed("Deaf") end
    if settings.volume <= 0 then return suppressed("volume") end
    if movement == "idle" or not movementGain[movement] or (snapshot.distance or 0) <= 0 then
        return suppressed("idle")
    end
    local distance = snapshot.distance or 0
    if snapshot.movementJump or snapshot.teleported or distance > maximumPlausibleDelta then
        return suppressed("movement jump")
    end
    local selected = snapshot.selected or Engine.select(snapshot, snapshot.overrides, snapshot.warn)
    if not selected then return suppressed("no firearm") end
    local stepDistance = cadenceDistance[movement]
    local traveled = (snapshot.cadenceDistance or 0) + distance
    if traveled < stepDistance then
        return { play = false, reason = "cadence distance", cadenceDistance = traveled,
            missedSteps = snapshot.missedSteps or 0 }
    end
    -- Consume only one eligible step. A large but plausible update may not
    -- create multiple accents in one frame; the remainder is carried forward.
    local remainder = traveled - stepDistance
    if remainder >= stepDistance then remainder = stepDistance - 0.000001 end
    if snapshot.activePlayback then
        return { play = false, reason = "active playback", cadenceDistance = remainder,
            missedSteps = snapshot.missedSteps or 0 }
    end
    local cadence = frequency[settings.frequency] or frequency.Normal
    local misses = snapshot.missedSteps or 0
    local play = randomValue(snapshot.random) < cadence.chance or misses >= cadence.maxMisses
    if not play then return { play = false, reason = "cadence", cadenceDistance = remainder,
        missedSteps = misses + 1 } end
    local profileGain = selected.profile == "handgun" and 0.80 or 1.0
    local carryGain = selected.carry == "held" and 0.55 or 1.0
    local hearingGain = snapshot.hearing == "Hard of Hearing" and 0.60 or 1.0
    local variation = 0.90 + randomValue(snapshot.random) * 0.20
    local pitch = 0.97 + randomValue(snapshot.random) * 0.06
    local pool = samples[selected.profile]
    local index = math.floor(randomValue(snapshot.random) * #pool) + 1
    if pool[index] == snapshot.lastSample then index = (index % #pool) + 1 end
    return { play = true, profile = selected.profile, carry = selected.carry, sample = pool[index],
        gain = movementGain[movement] * profileGain * carryGain * hearingGain * ((settings.volume or 50) / 100) * variation,
        pitch = pitch, cadenceDistance = remainder, missedSteps = 0 }
end

Engine.frequency = frequency
Engine.frequencyValues = frequencyValues
Engine.samples = samples
Engine.cadenceDistance = cadenceDistance
Engine.defaultSettings = defaultSettings
Engine.normalizeSettings = normalizeSettings
return Engine
