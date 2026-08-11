if PZAPI and PZAPI.ModOptions then
    local options = PZAPI.ModOptions:create("GunFirearmRattleSFX", "Gun / Firearm Rattle SFX")
    options:addBoolean("enabled", true, "Enable firearm movement Foley")
    options:addSlider("volume", 0, 100, 50, "Volume")
    options:addCombo("frequency", { "Very Low", "Low", "Normal", "High", "Very High" }, "Normal", "Frequency")
end
