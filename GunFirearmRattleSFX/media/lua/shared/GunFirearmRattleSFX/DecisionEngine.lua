local Engine = {}

local frequency = {
    ["Very Low"] = { chance = 0.20, maxMisses = 8 },
    Low = { chance = 0.35, maxMisses = 5 },
    Normal = { chance = 0.50, maxMisses = 3 },
    High = { chance = 0.70, maxMisses = 2 },
    ["Very High"] = { chance = 0.90, maxMisses = 1 },
}

local movementGain = { crouch = 0.45, walk = 0.65, jog = 0.85, sprint = 1.0 }
local samples = { handgun = { "Handgun01", "Handgun02", "Handgun03", "Handgun04" }, longGun = { "LongGun01", "LongGun02", "LongGun03", "LongGun04" } }

local function hasAny(item, keys)
    for _, key in ipairs(keys) do if item[key] then return true end end
    return false
end

function Engine.classify(item, overrides, warn)
    if type(item) ~= "table" or type(item.fullType) ~= "string" then return nil end
    local override = overrides and overrides[item.fullType]
    if override == "silent" then return nil end
    if override == "handgun" or override == "long gun" then
        return { profile = override == "long gun" and "longGun" or "handgun", evidence = "explicit override" }
    end
    if item.bow or item.crossbow or item.slingshot or item.nonFirearmRanged then return nil end
    local tagged = item.firearm == true or item.isFirearm == true
    local legacy = item.ranged and item.ammunition and hasAny(item, { "reloadable", "reloadTime", "firearmType", "magazineType" })
    if not tagged and not legacy then return nil end
    if item.longGun or item.longgun or item.twoHanded or (tonumber(item.weight) or 0) >= 2.5 then
        return { profile = "longGun", evidence = tagged and "firearm metadata" or "legacy firearm signals" }
    end
    if item.handgun then return { profile = "handgun", evidence = tagged and "firearm metadata" or "legacy firearm signals" } end
    if warn then warn(item.fullType, "ambiguous firearm metadata; fallback classification used") end
    return { profile = "handgun", evidence = "fallback: light or one-handed" }
end

function Engine.select(equipment, overrides, warn)
    local best, bestPriority
    local function consider(item, carry)
        local result = Engine.classify(item, overrides, warn)
        if not result then return end
        local priority = (carry == "attached" and result.profile == "longGun" and 4)
            or (carry == "held" and result.profile == "longGun" and 3)
            or (carry == "attached" and 2) or 1
        if not best or priority > bestPriority then
            best, bestPriority = { profile = result.profile, carry = carry, evidence = result.evidence, item = item }, priority
        end
    end
    for _, item in ipairs((equipment and equipment.attached) or {}) do consider(item, "attached") end
    for _, item in ipairs((equipment and equipment.held) or {}) do consider(item, "held") end
    return best
end

local function randomValue(random)
    local value = random and random() or math.random()
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

function Engine.decide(snapshot)
    local settings = snapshot.settings or { enabled = true, volume = 50, frequency = "Normal" }
    if not settings.enabled then return { play = false, reason = "disabled" } end
    if snapshot.aiming then return { play = false, reason = "aiming" } end
    if snapshot.inVehicle then return { play = false, reason = "vehicle" } end
    if snapshot.specialAction then return { play = false, reason = "special action" } end
    if snapshot.alternateLocomotion then return { play = false, reason = "alternate locomotion" } end
    if snapshot.hearing == "Deaf" then return { play = false, reason = "Deaf" } end
    if snapshot.movement == "idle" or not movementGain[snapshot.movement] or (snapshot.distance or 0) <= 0 then
        return { play = false, reason = "idle" }
    end
    local selected = Engine.select(snapshot, snapshot.overrides, snapshot.warn)
    if not selected then return { play = false, reason = "no firearm" } end
    if snapshot.activePlayback then return { play = false, reason = "active playback" } end
    local cadence = frequency[settings.frequency] or frequency.Normal
    local misses = snapshot.missedSteps or 0
    local play = randomValue(snapshot.random) < cadence.chance or misses >= cadence.maxMisses
    if not play then return { play = false, reason = "cadence", missedSteps = misses + 1 } end
    local profileGain = selected.profile == "handgun" and 0.80 or 1.0
    local carryGain = selected.carry == "held" and 0.55 or 1.0
    local hearingGain = snapshot.hearing == "Hard of Hearing" and 0.60 or 1.0
    local variation = 0.90 + randomValue(snapshot.random) * 0.20
    local pitch = 0.97 + randomValue(snapshot.random) * 0.06
    local pool = samples[selected.profile]
    local index = math.floor(randomValue(snapshot.random) * #pool) + 1
    if pool[index] == snapshot.lastSample then index = (index % #pool) + 1 end
    return { play = true, profile = selected.profile, carry = selected.carry, sample = pool[index],
        gain = movementGain[snapshot.movement] * profileGain * carryGain * hearingGain * ((settings.volume or 50) / 100) * variation,
        pitch = pitch, missedSteps = 0 }
end

Engine.frequency = frequency
Engine.samples = samples
return Engine
