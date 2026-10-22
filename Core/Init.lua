-- =========================================================================
-- Core/Init.lua
-- Event bus, ADDON_LOADED SavedVariables initialization, slash commands,
-- and native Minimap Addon Compartment hooks.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

-- -------------------------------------------------------------------------
-- Event Dispatcher & Message Bus
-- -------------------------------------------------------------------------
ns.eventFrame = CreateFrame("Frame")
ns.events = {}
ns.messages = {}

local function WithHandler(list, handler)
    local copy = {}
    for i, h in ipairs(list or {}) do copy[i] = h end
    copy[#copy + 1] = handler
    return copy
end

local function WithoutHandler(list, handler)
    local copy = {}
    for _, h in ipairs(list or {}) do
        if h ~= handler then copy[#copy + 1] = h end
    end
    return copy
end

local function Dispatch(handlers, ...)
    if not handlers then return end
    for _, handler in ipairs(handlers) do
        xpcall(handler, CallErrorHandler, ...)
    end
end

ns.eventFrame:SetScript("OnEvent", function(_, event, ...)
    Dispatch(ns.events[event], event, ...)
end)

function ns.RegisterEvent(event, handler)
    if not ns.events[event] then
        ns.eventFrame:RegisterEvent(event)
    end
    ns.events[event] = WithHandler(ns.events[event], handler)
end

function ns.UnregisterEvent(event, handler)
    local remaining = WithoutHandler(ns.events[event], handler)
    if #remaining == 0 then
        ns.events[event] = nil
        ns.eventFrame:UnregisterEvent(event)
    else
        ns.events[event] = remaining
    end
end

function ns.RegisterMessage(message, handler)
    ns.messages[message] = WithHandler(ns.messages[message], handler)
end

function ns.SendMessage(message, ...)
    Dispatch(ns.messages[message], ...)
end

-- -------------------------------------------------------------------------
-- Default SavedVariables Schema
-- -------------------------------------------------------------------------
local defaults = {
    theme = "PARCHMENT",        -- "PARCHMENT" or "DARK"
    groupByZone = false,       -- Group sidebar entries by Zone folders
    spoilerFree = true,        -- Hide full lore text until discovered in-game
    autoToast = true,          -- Show toast banner on new discovery
    windowPos = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
    discovered = {},           -- [entryKey] = timestamp
    discoveredMeta = {},       -- [entryKey] = { char = "Name-Realm", faction = "Alliance"|"Horde", time = timestamp }
    favorites = {},            -- [entryKey] = true
    notes = {},                -- [entryKey] = "field note text"
    books = {},                -- [bookKey] = { title, pages = { [1] = "text" }, ... }
    quests = {},               -- [questKey] = { title, description, resolution, ... }
    items = {},                -- [itemKey] = { title, flavorText, icon, ... }
    gossip = {},               -- [gossipKey] = { title, text, npc, ... }
    charFilter = "ALL",        -- "ALL" or "CURRENT"
    factionFilter = "ALL",     -- "ALL", "Alliance", "Horde", "Neutral"
    groupMode = "ZONE",        -- "ZONE" or "NONE"
    collapsedGroups = {},      -- [groupKey] = true
}

local function MergeDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            MergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

-- -------------------------------------------------------------------------
-- ADDON_LOADED Lifecycle
-- -------------------------------------------------------------------------
local function OnAddonLoaded(event, loadedAddon)
    if loadedAddon ~= addonName then return end
    ns.UnregisterEvent(event, OnAddonLoaded)

    if type(ChronicleWeaverDB) ~= "table" then
        ChronicleWeaverDB = {}
    end
    MergeDefaults(ChronicleWeaverDB, defaults)
    ns.db = ChronicleWeaverDB

    -- Ensure required sub-tables exist
    ns.db.discovered = ns.db.discovered or {}
    ns.db.discoveredMeta = ns.db.discoveredMeta or {}
    ns.db.favorites = ns.db.favorites or {}
    ns.db.notes = ns.db.notes or {}
    ns.db.books = ns.db.books or {}
    ns.db.quests = ns.db.quests or {}
    ns.db.items = ns.db.items or {}
    ns.db.gossip = ns.db.gossip or {}
    ns.db.collapsedGroups = ns.db.collapsedGroups or {}
    if ns.db.groupMode ~= "ZONE" and ns.db.groupMode ~= "NONE" then
        ns.db.groupMode = "ZONE"
    end

    -- Build runtime index from static data and hydrate saved entries
    if ns.BuildLoreIndex then
        ns.BuildLoreIndex()
    end

    -- Build bi-directional backlinks and topic clusters
    if ns.RebuildLoreWeb then
        ns.RebuildLoreWeb()
    end

    ns.SendMessage("ADDON_INITIALIZED")
end

ns.RegisterEvent("ADDON_LOADED", OnAddonLoaded)

-- -------------------------------------------------------------------------
-- Native Minimap Addon Compartment Callbacks (Interface 16001)
-- -------------------------------------------------------------------------
function ChronicleWeaver_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        ns.db.spoilerFree = not ns.db.spoilerFree
        ns.Print("Spoiler-Safe Mode: " .. (ns.db.spoilerFree and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
        if ns.RefreshUI then ns.RefreshUI() end
    else
        if ns.ToggleMainFrame then
            ns.ToggleMainFrame()
        elseif ns.CodexFrame and ns.CodexFrame.Toggle then
            ns.CodexFrame:Toggle()
        end
    end
end

function ChronicleWeaver_OnAddonCompartmentEnter(_, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText("ChronicleWeaver", 1, 0.82, 0.45)
    GameTooltip:AddLine("Left-Click: Toggle Lore Codex", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("Right-Click: Toggle Spoiler-Safe Mode", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end

function ChronicleWeaver_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

-- -------------------------------------------------------------------------
-- Slash Commands (/cw, /lorecodex)
-- -------------------------------------------------------------------------
SLASH_CHRONICLEWEAVER1 = "/cw"
SLASH_CHRONICLEWEAVER2 = "/lorecodex"

SlashCmdList["CHRONICLEWEAVER"] = function(msg)
    local cmd = strtrim(msg or ""):lower()

    if cmd == "theme" then
        ns.db.theme = (ns.db.theme == "DARK") and "PARCHMENT" or "DARK"
        ns.Print("Active Theme: |cffffd100" .. ns.db.theme .. "|r")
        if ns.ApplyTheme then ns.ApplyTheme() end
        if ns.RefreshUI then ns.RefreshUI() end
    elseif cmd == "spoilers" then
        ns.db.spoilerFree = not ns.db.spoilerFree
        ns.Print("Spoiler-Safe Mode: " .. (ns.db.spoilerFree and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
        if ns.RefreshUI then ns.RefreshUI() end
    elseif cmd == "toast" then
        ns.db.autoToast = not ns.db.autoToast
        ns.Print("Discovery Toasts: " .. (ns.db.autoToast and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
    elseif cmd == "scan" or cmd == "quests" then
        if ns.ScanActiveQuestLog then
            ns.ScanActiveQuestLog()
            ns.Print("Scanned your active Quest Log for chronicles.")
            if ns.RefreshUI then ns.RefreshUI() end
        elseif ns.ScanQuestLog then
            ns.ScanQuestLog()
            ns.Print("Scanned your active Quest Log for chronicles.")
            if ns.RefreshUI then ns.RefreshUI() end
        else
            ns.Print("Quest scanner engine not yet initialized.")
        end
    elseif cmd == "help" then
        ns.Print("Available Commands:")
        print("  |cffffd100/cw|r - Open/Close the Tome")
        print("  |cffffd100/cw theme|r - Toggle between Parchment & Dark modes")
        print("  |cffffd100/cw spoilers|r - Toggle Spoiler-Safe mode")
        print("  |cffffd100/cw toast|r - Toggle Discovery Toast banners")
        print("  |cffffd100/cw scan|r - Harvest lore from active Quest Log")
    else
        if ns.ToggleMainFrame then
            ns.ToggleMainFrame()
        elseif ns.CodexFrame and ns.CodexFrame.Toggle then
            ns.CodexFrame:Toggle()
        else
            ns.Print("ChronicleWeaver UI is loading...")
        end
    end
end
