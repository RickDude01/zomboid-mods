local Compatibility = { overrides = {}, warned = {}, version = 0 }
local valid = { handgun = "handgun", longgun = "longgun", ["long gun"] = "longgun", silent = "silent" }
local warningText = {
    ["invalid compatibility item ID"] = "UI_GunFirearmRattleSFX_InvalidItemID",
    ["invalid compatibility classification"] = "UI_GunFirearmRattleSFX_InvalidClassification",
    ["compatibility override replaced"] = "UI_GunFirearmRattleSFX_OverrideReplaced",
    ["malformed firearm item metadata"] = "UI_GunFirearmRattleSFX_MalformedItem",
}

local function localized(message)
    local key
    for prefix, candidate in pairs(warningText) do
        if string.find(message, prefix, 1, true) == 1 then key = candidate; break end
    end
    if key and getText then
        local ok, value = pcall(getText, key)
        if ok and value and value ~= key then return value end
    end
    return message
end

local function warnOnce(key, message)
    if Compatibility.warned[key] then return end
    Compatibility.warned[key] = true
    print("[GunFirearmRattleSFX] " .. localized(message))
end

function Compatibility.registerItem(fullType, classification)
    local canonical = valid[classification]
    if type(fullType) ~= "string" or fullType == "" then
        warnOnce("invalid registration id:" .. tostring(fullType), "invalid compatibility item ID")
        return false
    end
    if not canonical then
        warnOnce("invalid registration classification:" .. fullType,
            "invalid compatibility classification (" .. fullType .. ")")
        return false
    end
    if Compatibility.overrides[fullType] ~= nil then
        warnOnce("replacement:" .. fullType, "compatibility override replaced: " .. fullType)
    end
    Compatibility.overrides[fullType] = canonical
    Compatibility.version = Compatibility.version + 1
    return true
end

-- Kept as a source-compatible alias for integrations shipped during 0.1.0.
Compatibility.register = Compatibility.registerItem

function Compatibility.warnOnce(fullType, message)
    if type(fullType) ~= "string" then return end
    warnOnce("classification:" .. fullType, message .. " (" .. fullType .. ")")
end
function Compatibility.warnMalformed(fullType)
    if type(fullType) ~= "string" then return end
    warnOnce("malformed:" .. fullType, "malformed firearm item metadata (" .. fullType .. ")")
end
function Compatibility.diagnose(snapshot, engine)
    snapshot.overrides = snapshot.overrides or Compatibility.overrides
    local selected = engine.select(snapshot, Compatibility.overrides, Compatibility.warnOnce)
    snapshot.selected = selected
    local decision = engine.decide(snapshot)
    return { items = { held = snapshot.held or {}, attached = snapshot.attached or {} }, selected = selected,
        settings = snapshot.settings, suppression = decision.play and nil or decision.reason, decision = decision }
end
return Compatibility
