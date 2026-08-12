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

local function test_stable_exact_item_api_accepts_longgun_and_overrides_heuristics()
    assertTrue(Compatibility.registerItem("VanillaWeaponsPlus.Base.Pistolm93r", "longgun"))
    local selected = Engine.select({ held = { item({
        fullType = "VanillaWeaponsPlus.Base.Pistolm93r",
        firearm = false,
    }) } }, Compatibility.overrides)
    assertEqual(selected.profile, "longGun")
    assertEqual(selected.evidence, "explicit override")
end

local function test_silent_override_and_invalid_registration_warn_once_without_throwing()
    local warnings = 0
    local originalPrint = print
    print = function() warnings = warnings + 1 end
    assertTrue(Compatibility.registerItem("Mod.SilentItem", "silent"))
    assertEqual(Compatibility.registerItem("", "handgun"), false)
    assertEqual(Compatibility.registerItem("Mod.Invalid", "rifle"), false)
    assertEqual(Compatibility.registerItem("Mod.Invalid", "rifle"), false)
    print = originalPrint

    assertEqual(warnings, 2, "invalid API calls warn once per item")
    assertEqual(Engine.select({ held = { item({ fullType = "Mod.SilentItem", firearm = true }) } }, Compatibility.overrides), nil)
end

local function test_reregistration_is_last_write_wins_and_warns_once()
    local warnings = 0
    local originalPrint = print
    print = function() warnings = warnings + 1 end
    assertTrue(Compatibility.registerItem("Mod.Conflict", "handgun"))
    assertTrue(Compatibility.registerItem("Mod.Conflict", "longgun"))
    assertTrue(Compatibility.registerItem("Mod.Conflict", "handgun"))
    print = originalPrint

    assertEqual(warnings, 1, "replacement warning is deduplicated")
    local selected = Engine.select({ held = { item({ fullType = "Mod.Conflict" }) } }, Compatibility.overrides)
    assertEqual(selected.profile, "handgun")
end

local function test_diagnostic_report_exposes_selection_settings_and_suppression()
    local report = Compatibility.diagnose({
        held = { item({ fullType = "Base.Pistol", firearm = true, handgun = true }) },
        attached = {},
        settings = { enabled = true, volume = 50, frequency = "Normal" },
        movement = "idle",
        distance = 0,
    }, Engine)
    assertEqual(report.selected.profile, "handgun")
    assertEqual(report.selected.carry, "held")
    assertEqual(report.selected.evidence, "firearm metadata")
    assertEqual(report.settings.volume, 50)
    assertEqual(report.suppression, "idle")
end

test_stable_exact_item_api_accepts_longgun_and_overrides_heuristics()
test_silent_override_and_invalid_registration_warn_once_without_throwing()
test_reregistration_is_last_write_wins_and_warns_once()
test_diagnostic_report_exposes_selection_settings_and_suppression()
print("compatibility_test: 4 passed")
