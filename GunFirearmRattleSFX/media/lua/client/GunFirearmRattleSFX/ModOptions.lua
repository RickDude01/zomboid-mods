if PZAPI and PZAPI.ModOptions then
    local options = PZAPI.ModOptions:create(
        "GunFirearmRattleSFX",
        getText("UI_GunFirearmRattleSFX_Title")
    )
    options:addTickBox(
        "enabled",
        getText("UI_GunFirearmRattleSFX_Enabled"),
        true,
        getText("UI_GunFirearmRattleSFX_EnabledTooltip")
    )
    options:addSlider(
        "volume",
        getText("UI_GunFirearmRattleSFX_Volume"),
        0,
        100,
        1,
        50,
        getText("UI_GunFirearmRattleSFX_VolumeTooltip")
    )
    local frequency = options:addComboBox(
        "frequency",
        getText("UI_GunFirearmRattleSFX_Frequency"),
        getText("UI_GunFirearmRattleSFX_FrequencyTooltip")
    )
    local frequencyLabels = {
        "UI_GunFirearmRattleSFX_FrequencyVeryLow",
        "UI_GunFirearmRattleSFX_FrequencyLow",
        "UI_GunFirearmRattleSFX_FrequencyNormal",
        "UI_GunFirearmRattleSFX_FrequencyHigh",
        "UI_GunFirearmRattleSFX_FrequencyVeryHigh",
    }
    for index, key in ipairs(frequencyLabels) do
        frequency:addItem(getText(key), index == 3)
    end

    -- The native API owns persistence in the user's global ModOptions.ini.
    -- Keep the object available so the runtime observes applied changes immediately.
    GunFirearmRattleSFXModOptions = options
end
