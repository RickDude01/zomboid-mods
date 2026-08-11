local Engine = dofile("media/lua/shared/GunFirearmRattleSFX/DecisionEngine.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function assertTrue(value, message)
    assertEqual(value, true, message)
end

local function item(fields)
    fields = fields or {}
    fields.fullType = fields.fullType or "Base.Pistol"
    return fields
end

local function snapshot(fields)
    fields = fields or {}
    fields.settings = fields.settings or { enabled = true, volume = 50, frequency = "Normal" }
    fields.movement = fields.movement or "walk"
    fields.distance = fields.distance or 0.5
    fields.random = fields.random or function() return 0 end
    return fields
end

local function test_classifies_vanilla_firearms()
    local result = Engine.classify(item({ firearm = true, handgun = true }))
    assertEqual(result.profile, "handgun")
    assertEqual(result.evidence, "firearm metadata")
end

local function test_rejects_ranged_non_firearms()
    local result = Engine.classify(item({ ranged = true, ammunition = true, bow = true }))
    assertEqual(result, nil, "bows are not firearms")
end

local function test_selects_attached_long_gun_over_held_handgun()
    local result = Engine.select({
        held = { item({ firearm = true, handgun = true }) },
        attached = { item({ firearm = true, longGun = true, attachment = "back" }) },
    })
    assertEqual(result.profile, "longGun")
    assertEqual(result.carry, "attached")
end

local function test_suppresses_aiming_and_idle()
    assertEqual(Engine.decide(snapshot({ aiming = true, held = { item({ firearm = true, handgun = true }) } })).reason, "aiming")
    assertEqual(Engine.decide(snapshot({ movement = "idle", held = { item({ firearm = true, handgun = true }) } })).reason, "idle")
end

local function test_produces_bounded_playback_decision()
    local result = Engine.decide(snapshot({
        held = { item({ firearm = true, handgun = true }) },
        distance = 1.0,
        random = function() return 0.4 end,
    }))
    assertTrue(result.play, "eligible movement should play at deterministic normal cadence")
    assertTrue(result.gain > 0 and result.gain <= 1, "gain is normalized")
    assertTrue(result.pitch >= 0.97 and result.pitch <= 1.03, "pitch variation is bounded")
end

local tests = {
    test_classifies_vanilla_firearms,
    test_rejects_ranged_non_firearms,
    test_selects_attached_long_gun_over_held_handgun,
    test_suppresses_aiming_and_idle,
    test_produces_bounded_playback_decision,
}

for _, test in ipairs(tests) do test() end
print("decision_engine_test: " .. #tests .. " passed")
