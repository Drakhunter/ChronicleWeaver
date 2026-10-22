-- =========================================================================
-- UI/Settings.lua
-- Native Blizzard Settings panel (Esc > Options > AddOns > ChronicleWeaver).
-- =========================================================================
local addonName, ns = ...
local L = ns.L

local OPTIONS = {
    { key = "spoilerFree", label = L.OPTION_SPOILER, tooltip = L.OPTION_SPOILER_TOOLTIP },
    { key = "autoToast", label = L.OPTION_TOAST, tooltip = L.OPTION_TOAST_TOOLTIP },
}

ns.OnAddonLoaded(function()
    local category = Settings.RegisterVerticalLayoutCategory(addonName)

    for _, option in ipairs(OPTIONS) do
        local key = option.key
        local setting = Settings.RegisterAddOnSetting(
            category,
            addonName .. "_" .. key,
            key,
            ns.db,
            Settings.VarType.Boolean,
            option.label,
            ns.DEFAULTS[key]
        )
        setting:SetValueChangedCallback(function(_, value)
            ns.SendMessage("OPTION_CHANGED", key, value)
        end)
        Settings.CreateCheckbox(category, setting, option.tooltip)

        -- ns.SetOption routes through this so the panel stays in sync
        ns.optionSettings[key] = setting
    end

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end)

function ns.OpenSettings()
    if ns.settingsCategory then
        Settings.OpenToCategory(ns.settingsCategory:GetID())
    end
end
