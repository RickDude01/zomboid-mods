local calls = {}
local combo = { items = {}, value = nil }
function combo:addItem(value, selected) table.insert(self.items, { value = value, selected = selected }) end

local options = {}
function options:addTickBox(id, name, value, tooltip)
    calls.enabled = { id, name, value, tooltip }
end
function options:addSlider(id, name, minimum, maximum, step, value, tooltip)
    calls.volume = { id, name, minimum, maximum, step, value, tooltip }
end
function options:addComboBox(id, name, tooltip)
    calls.frequency = { id, name, tooltip }
    return combo
end
function options:getOption() return nil end

PZAPI = { ModOptions = {} }
function PZAPI.ModOptions:create(id, name)
    calls.title = { id, name }
    return options
end
function getText(key) return key end

dofile("media/lua/client/GunFirearmRattleSFX/ModOptions.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end

assertEqual(calls.title[1], "GunFirearmRattleSFX")
assertEqual(calls.title[2], "UI_GunFirearmRattleSFX_Title")
assertEqual(calls.enabled[3], true, "enabled default")
assertEqual(calls.volume[3], 0, "volume minimum")
assertEqual(calls.volume[4], 100, "volume maximum")
assertEqual(calls.volume[5], 1, "volume step")
assertEqual(calls.volume[6], 50, "volume default")
assertEqual(#combo.items, 5, "frequency count")
assertEqual(combo.items[1].value, "UI_GunFirearmRattleSFX_FrequencyVeryLow")
assertEqual(combo.items[3].value, "UI_GunFirearmRattleSFX_FrequencyNormal")
assertEqual(combo.items[3].selected, true, "frequency default")
assertEqual(combo.items[5].value, "UI_GunFirearmRattleSFX_FrequencyVeryHigh")
assertEqual(GunFirearmRattleSFXModOptions, options, "native options retained for live reads")
print("mod_options_test: passed")
