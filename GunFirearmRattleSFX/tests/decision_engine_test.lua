local Engine = dofile("media/lua/shared/GunFirearmRattleSFX/DecisionEngine.lua")
local Compatibility = dofile("media/lua/shared/GunFirearmRattleSFX/Compatibility.lua")

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
    local result = Engine.classify(item({ fullType = "Base.Pistol", firearm = true, handgun = true }))
    assertEqual(result.profile, "handgun")
    assertEqual(result.evidence, "firearm metadata")

    result = Engine.classify(item({ fullType = "Base.Shotgun", firearm = true, twoHanded = true }))
    assertEqual(result.profile, "longGun")
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

local function test_selects_one_deterministic_profile_for_duplicate_and_equal_priority_items()
    local duplicate = item({ fullType = "Base.Duplicate", firearm = true, twoHanded = true })
    local result = Engine.select({
        held = { duplicate, duplicate },
        attached = {},
    })
    assertEqual(result.profile, "longGun")
    assertEqual(result.item.fullType, "Base.Duplicate")

    result = Engine.select({
        held = {
            item({ fullType = "Base.Zulu", firearm = true, handgun = true }),
            item({ fullType = "Base.Alpha", firearm = true, handgun = true }),
        },
    })
    assertEqual(result.item.fullType, "Base.Alpha", "equal priority selection is stable")
end

local function test_uses_legacy_signals_and_ambiguous_fallback()
    local result = Engine.classify(item({
        fullType = "Legacy.Rifle",
        ranged = true,
        ammunition = true,
        reloadable = true,
        handgun = true,
    }))
    assertEqual(result.profile, "handgun")
    assertEqual(result.evidence, "legacy firearm signals")

    result = Engine.classify(item({ fullType = "Mod.Ambiguous", firearm = true, weight = 3.0 }))
    assertEqual(result.profile, "longGun")
    assertEqual(result.evidence, "fallback: heavy or two-handed")
end

local function test_reports_each_ambiguous_item_once()
    local warnings = 0
    local originalPrint = print
    print = function() warnings = warnings + 1 end
    local ambiguous = item({ fullType = "Mod.Ambiguous", firearm = true })
    local result = Engine.select({ held = { ambiguous, ambiguous } }, nil, Compatibility.warnOnce)
    print = originalPrint
    assertEqual(result.profile, "handgun")
    assertEqual(warnings, 1, "ambiguous item warnings are deduplicated")
end

local function test_malformed_equipment_fails_silent()
    assertEqual(Engine.select({ held = "not a list", attached = {} }), nil)
    assertEqual(Engine.select({ held = { false, { fullType = 12 } }, attached = false }), nil)
end

local function test_suppresses_aiming_and_idle()
    assertEqual(Engine.decide(snapshot({ aiming = true, held = { item({ firearm = true, handgun = true }) } })).reason, "aiming")
    assertEqual(Engine.decide(snapshot({ movement = "idle", held = { item({ firearm = true, handgun = true }) } })).reason, "idle")
end

local function test_all_grounded_movement_classes_use_distance_cadence()
    for _, movement in ipairs({ "crouch", "walk", "jog", "sprint", "injured" }) do
        local result = Engine.decide(snapshot({ movement = movement, distance = 1.0,
            held = { item({ firearm = true, handgun = true }) }, random = function() return 0 end }))
        assertTrue(result.play, movement .. " movement should be eligible from traveled distance")
    end
end

local function test_small_updates_accumulate_until_a_step_without_frame_rate_cadence()
    local fields = { movement = "walk", held = { item({ firearm = true, handgun = true }) },
        cadenceDistance = 0, distance = 0.2, random = function() return 0 end }
    local first = Engine.decide(snapshot(fields))
    assertEqual(first.play, false, "partial distance should not play")
    assertEqual(first.reason, "cadence distance")
    fields.cadenceDistance = first.cadenceDistance
    fields.distance = 0.2
    local second = Engine.decide(snapshot(fields))
    assertEqual(second.play, false, "partial distance should remain silent")
    fields.cadenceDistance = second.cadenceDistance
    fields.distance = 0.2
    local third = Engine.decide(snapshot(fields))
    assertTrue(third.play, "accent should follow accumulated distance")
end

local function test_injured_movement_has_fewer_accents_for_the_same_distance()
    local healthy = Engine.decide(snapshot({ movement = "walk", distance = 0.5,
        held = { item({ firearm = true, handgun = true }) }, random = function() return 0 end }))
    local injured = Engine.decide(snapshot({ movement = "injured", distance = 0.5,
        held = { item({ firearm = true, handgun = true }) }, random = function() return 0 end }))
    assertTrue(healthy.play, "normal walk should reach its cadence")
    assertEqual(injured.play, false, "injured movement should require more traveled distance")
end

local function test_suppression_and_stops_reset_cadence_without_burst()
    local firearm = { item({ firearm = true, handgun = true }) }
    local partial = Engine.decide(snapshot({ movement = "walk", distance = 0.2, held = firearm }))
    local suppressed = Engine.decide(snapshot({ movement = "walk", distance = 0.8,
        cadenceDistance = partial.cadenceDistance, aiming = true, held = firearm }))
    assertEqual(suppressed.cadenceDistance, 0, "suppression resets cadence")
    local after = Engine.decide(snapshot({ movement = "walk", distance = 0.2,
        cadenceDistance = suppressed.cadenceDistance, held = firearm }))
    assertEqual(after.play, false, "stopping or suppression must not create a burst")
end

local function test_special_actions_and_alternate_locomotion_are_silent()
    local firearm = { item({ firearm = true, handgun = true }) }
    for _, fields in ipairs({ { inVehicle = true }, { specialAction = true },
        { alternateLocomotion = true }, { equipping = true }, { drawing = true },
        { attaching = true }, { detaching = true }, { holstering = true } }) do
        fields.held = firearm; fields.distance = 1.0
        local result = Engine.decide(snapshot(fields))
        assertEqual(result.play, false, "suppressed action should not play")
    end
end

local function test_unrealistic_position_jump_is_clamped()
    local result = Engine.decide(snapshot({ movement = "sprint", distance = 20,
        held = { item({ firearm = true, handgun = true }) } }))
    assertEqual(result.play, false, "teleports must not cause a playback burst")
    assertEqual(result.reason, "movement jump")
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

local function test_frequency_levels_have_approved_probability_and_streak_limits()
    local expected = {
        ["Very Low"] = { 0.20, 8 }, Low = { 0.35, 5 }, Normal = { 0.50, 3 },
        High = { 0.70, 2 }, ["Very High"] = { 0.90, 1 },
    }
    for name, values in pairs(expected) do
        assertEqual(Engine.frequency[name].chance, values[1], name .. " chance")
        assertEqual(Engine.frequency[name].maxMisses, values[2], name .. " max misses")
    end
end

local function test_forced_accent_ends_the_maximum_silent_streak()
    local fields = snapshot({ movement = "walk", distance = 0.5,
        held = { item({ firearm = true, handgun = true }) },
        settings = { enabled = true, volume = 50, frequency = "Very Low" },
        random = function() return 0.99 end })
    local missed = 0
    for _ = 1, Engine.frequency["Very Low"].maxMisses do
        local result = Engine.decide(fields)
        assertEqual(result.play, false, "silent streak should remain below the limit")
        missed = missed + 1
        fields.missedSteps, fields.cadenceDistance = result.missedSteps, result.cadenceDistance
    end
    local forced = Engine.decide(fields)
    assertTrue(forced.play, "the next eligible step must force an accent")
    assertEqual(forced.missedSteps, 0)
end

local function test_active_playback_skips_without_overlapping()
    local result = Engine.decide(snapshot({ distance = 0.5, activePlayback = true,
        held = { item({ firearm = true, handgun = true }) }, random = function() return 0 end }))
    assertEqual(result.play, false)
    assertEqual(result.reason, "active playback")
end

local function test_sample_selection_avoids_immediate_repeat()
    local result = Engine.decide(snapshot({ distance = 0.5, lastSample = "Handgun01",
        held = { item({ firearm = true, handgun = true }) }, random = function() return 0 end }))
    assertTrue(result.play)
    assertEqual(result.sample, "Handgun02")
end

local function test_gain_factors_follow_movement_profile_carry_and_hearing()
    local function decide(fields)
        fields.distance = 1.0
        fields.random = function() return 0.4 end
        fields.settings = { enabled = true, volume = 100, frequency = "Normal" }
        return Engine.decide(snapshot(fields)).gain
    end
    local attachedLongGun = decide({ movement = "sprint", hearing = "Keen Hearing",
        attached = { item({ firearm = true, longGun = true }) } })
    local heldHandgun = decide({ movement = "crouch", hearing = "Hard of Hearing",
        held = { item({ firearm = true, handgun = true }) } })
    assertEqual(attachedLongGun, 1.0 * 0.98, "long-gun sprint gain")
    assertEqual(heldHandgun, 0.45 * 0.80 * 0.55 * 0.60 * 0.98, "held handgun hearing gain")
end

local function test_settings_have_safe_defaults_and_legal_ranges()
    local defaults = Engine.normalizeSettings()
    assertEqual(defaults.enabled, true)
    assertEqual(defaults.volume, 50)
    assertEqual(defaults.frequency, "Normal")
    local normalized = Engine.normalizeSettings({ enabled = false, volume = -20, frequency = "invalid" })
    assertEqual(normalized.enabled, false)
    assertEqual(normalized.volume, 0)
    assertEqual(normalized.frequency, "Normal")
    normalized = Engine.normalizeSettings({ volume = 200, frequency = "Very High" })
    assertEqual(normalized.volume, 100)
    assertEqual(normalized.frequency, "Very High")
end

local function test_zero_volume_suppresses_playback()
    local result = Engine.decide(snapshot({
        settings = { enabled = true, volume = 0, frequency = "Normal" },
        distance = 1.0, held = { item({ firearm = true, handgun = true }) },
    }))
    assertEqual(result.play, false)
    assertEqual(result.reason, "volume")
end

local function test_live_enablement_hearing_and_frequency_index_are_applied()
    local fields = snapshot({ distance = 1.0, held = { item({ firearm = true, handgun = true }) } })
    fields.settings = { enabled = false, volume = 100, frequency = 5 }
    assertEqual(Engine.decide(fields).reason, "disabled")
    fields.settings.enabled = true
    fields.hearing = "Deaf"
    assertEqual(Engine.decide(fields).reason, "Deaf")
    fields.hearing = "Hard of Hearing"
    local result = Engine.decide(fields)
    assertTrue(result.play, "live settings should be read on the next decision")
    assertEqual(Engine.normalizeSettings({ frequency = 5 }).frequency, "Very High")
end

local tests = {
    test_classifies_vanilla_firearms,
    test_rejects_ranged_non_firearms,
    test_selects_attached_long_gun_over_held_handgun,
    test_selects_one_deterministic_profile_for_duplicate_and_equal_priority_items,
    test_uses_legacy_signals_and_ambiguous_fallback,
    test_reports_each_ambiguous_item_once,
    test_malformed_equipment_fails_silent,
    test_suppresses_aiming_and_idle,
    test_all_grounded_movement_classes_use_distance_cadence,
    test_small_updates_accumulate_until_a_step_without_frame_rate_cadence,
    test_injured_movement_has_fewer_accents_for_the_same_distance,
    test_suppression_and_stops_reset_cadence_without_burst,
    test_special_actions_and_alternate_locomotion_are_silent,
    test_unrealistic_position_jump_is_clamped,
    test_produces_bounded_playback_decision,
    test_frequency_levels_have_approved_probability_and_streak_limits,
    test_forced_accent_ends_the_maximum_silent_streak,
    test_active_playback_skips_without_overlapping,
    test_sample_selection_avoids_immediate_repeat,
    test_gain_factors_follow_movement_profile_carry_and_hearing,
    test_settings_have_safe_defaults_and_legal_ranges,
    test_zero_volume_suppresses_playback,
    test_live_enablement_hearing_and_frequency_index_are_applied,
}

for _, test in ipairs(tests) do test() end
print("decision_engine_test: " .. #tests .. " passed")
