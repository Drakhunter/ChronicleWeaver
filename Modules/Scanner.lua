-- =========================================================================
-- Modules/Scanner.lua
-- Context discovery: zones/subzones, targeted NPCs and tooltips.
-- =========================================================================
local _, ns = ...
local L = ns.L

-- -------------------------------------------------------------------------
-- Zone & subzone (subzone wins, so dungeon wings beat their parent zone)
-- -------------------------------------------------------------------------
local function CheckCurrentZone()
    local subzone = ns.SafeString(GetSubZoneText(), "")
    local zone = ns.SafeString(GetRealZoneText(), "")

    local entryKey = (subzone ~= "" and ns.LoreByZone[subzone:lower()])
        or (zone ~= "" and ns.LoreByZone[zone:lower()])

    if entryKey then
        ns.UnlockEntry(entryKey)
    end
end

ns.RegisterEvent("PLAYER_ENTERING_WORLD", CheckCurrentZone)
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", CheckCurrentZone)
ns.RegisterEvent("ZONE_CHANGED", CheckCurrentZone)
ns.RegisterEvent("ZONE_CHANGED_INDOORS", CheckCurrentZone)

-- -------------------------------------------------------------------------
-- Targeted NPCs (secret-value guarded)
-- -------------------------------------------------------------------------
--- @return string|nil entryKey
local function GetEntryKeyForUnitName(name)
    name = ns.SafeString(name)
    return name and ns.LoreByNPC[name:lower()]
end

ns.RegisterEvent("PLAYER_TARGET_CHANGED", function()
    local entryKey = GetEntryKeyForUnitName(UnitName("target"))
    if entryKey then
        ns.UnlockEntry(entryKey)
    end
end)

-- -------------------------------------------------------------------------
-- Tooltips
-- -------------------------------------------------------------------------
local function AddLoreLines(tooltip, entryKey, lockedHint)
    local entry = ns.LoreByKey[entryKey]
    tooltip:AddLine(" ")
    tooltip:AddLine(ns.Colorize(ns.COLORS.gold, L.TOOLTIP_HEADER))
    if not lockedHint or ns.CanReveal(entryKey) then
        tooltip:AddLine(entry.summary, 0.9, 0.85, 0.7, true)
    else
        tooltip:AddLine(lockedHint, 0.6, 0.6, 0.6, true)
    end
end

-- NPCs: show a teaser, unlock only on target
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
    if tooltip ~= GameTooltip or not ns.db then return end

    local entryKey = GetEntryKeyForUnitName(tooltip:GetUnit())
    if entryKey then
        AddLoreLines(tooltip, entryKey, L.TOOLTIP_LOCKED_NPC)
    end
end)

-- Items: inspecting a relic's tooltip discovers it
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
    if tooltip ~= GameTooltip or not ns.db or not data then return end

    local itemID = data.id
    if type(itemID) ~= "number" or ns.IsSecret(itemID) then return end

    local entryKey = ns.LoreByItem[itemID]
    if entryKey then
        ns.UnlockEntry(entryKey)
        AddLoreLines(tooltip, entryKey)
    end
end)
