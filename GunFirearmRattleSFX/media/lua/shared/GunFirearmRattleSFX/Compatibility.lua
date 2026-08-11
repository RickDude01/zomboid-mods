local Compatibility = { overrides = {}, warned = {} }
local valid = { handgun = true, ["long gun"] = true, silent = true }
function Compatibility.register(fullType, classification)
    if type(fullType) ~= "string" or fullType == "" or not valid[classification] then return false end
    if Compatibility.overrides[fullType] ~= nil and not Compatibility.warned[fullType] then
        Compatibility.warned[fullType] = true
        print("[GunFirearmRattleSFX] compatibility override replaced: " .. fullType)
    end
    Compatibility.overrides[fullType] = classification
    return true
end
function Compatibility.warnOnce(fullType, message)
    if type(fullType) ~= "string" or Compatibility.warned[fullType] then return end
    Compatibility.warned[fullType] = true
    print("[GunFirearmRattleSFX] " .. message .. " (" .. fullType .. ")")
end
function Compatibility.diagnose(snapshot, engine)
    local selected = engine.select(snapshot, Compatibility.overrides)
    local decision = engine.decide(snapshot)
    return { items = { held = snapshot.held or {}, attached = snapshot.attached or {} }, selected = selected,
        settings = snapshot.settings, suppression = decision.play and nil or decision.reason, decision = decision }
end
return Compatibility
