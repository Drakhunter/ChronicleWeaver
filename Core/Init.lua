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
    toastSound = true,         -- Play sound effect on discovery toast banner
    chatAlerts = true,         -- Print automatic harvest messages in chat
    trackQuests = true,        -- Automatically harvest quest narratives & resolutions
    trackBooks = true,         -- Automatically harvest in-game books & plaques
    trackRelics = true,        -- Automatically harvest bag/tooltip relics & library books
    trackWorld = true,         -- Automatically unlock zones, subzones & target NPCs
    showTooltips = true,       -- Show lore lines on NPC and item tooltips
    showDeliveryHints = true,  -- Show librarian turn-in hints on deliverable books
    showGossipButton = true,   -- Show [+] Archive Lore button on GossipFrame
    proximityRadar = true,     -- Alert when approaching unrecorded books or chronicles
    showMapOverlay = true,     -- Show ChronicleWeaver zone progress bar on WorldMapFrame
    addonSync = true,          -- Allow party/guild lore link sharing over CW_LORE
    soundStyle = "CHIME",      -- "CHIME", "PAGETURN", "FANFARE", or "MUTE"
    toastLocked = false,       -- Lock Discovery Toast position
    toastPos = { point = "TOP", relPoint = "TOP", x = 0, y = -120 },
    storytellerMode = false,   -- Collapse sidebar for wide-page reading
    windowPos = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
    discovered = {},           -- [entryKey] = timestamp
    discoveredMeta = {},       -- [entryKey] = { char = "Name-Realm", faction = "Alliance"|"Horde", time = timestamp }
    favorites = {},            -- [entryKey] = true
    notes = {},                -- [entryKey] = "field note text"
    books = {},                -- [bookKey] = { title, pages = { [1] = "text" }, ... }
    quests = {},               -- [questKey] = { title, description, resolution, ... }
    items = {},                -- [itemKey] = { title, flavorText, icon, ... }
    gossip = {},               -- [gossipKey] = { title, text, npc, ... }
    completedLibraryBooks = {},-- [itemID] = true (turned in)
    scrollPositions = {},      -- [entryKey] = scrollOffset
    charFilter = "ALL",        -- "ALL" or "CURRENT"
    factionFilter = "ALL",     -- "ALL", "Alliance", "Horde", "Neutral"
    eraFilter = "ALL",         -- "ALL", "FOREVER", "CLASSIC", "HARVEST"
    groupMode = "ZONE",        -- "ZONE", "ERA", or "NONE"
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
    ns.db.completedLibraryBooks = ns.db.completedLibraryBooks or {}
    ns.db.scrollPositions = ns.db.scrollPositions or {}
    ns.db.collapsedGroups = ns.db.collapsedGroups or {}
    if ns.db.groupMode ~= "ZONE" and ns.db.groupMode ~= "ERA" and ns.db.groupMode ~= "NONE" then
        ns.db.groupMode = "ZONE"
    end
    if ns.db.eraFilter ~= "ALL" and ns.db.eraFilter ~= "FOREVER" and ns.db.eraFilter ~= "CLASSIC" and ns.db.eraFilter ~= "HARVEST" then
        ns.db.eraFilter = "ALL"
    end
    if ns.db.charFilter ~= "ALL" and ns.db.charFilter ~= "CURRENT" then
        ns.db.charFilter = "ALL"
    end

    -- Auto-heal any duplicate quest descriptions before building index
    if ns.SanitizeDuplicateQuests then
        ns.SanitizeDuplicateQuests()
    end

    -- Build runtime index from static data and hydrate saved entries
    if ns.BuildLoreIndex then
        ns.BuildLoreIndex()
    elseif ns.RebuildLoreWeb then
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
    elseif cmd == "char" or cmd == "scope" then
        ns.db.charFilter = (ns.db.charFilter == "CURRENT") and "ALL" or "CURRENT"
        ns.Print("Chronicle Scope: " .. (ns.db.charFilter == "CURRENT" and ("|cff4cd964Current Character (" .. ns.GetPlayerKey() .. ")|r") or "|cffffd100Account-Wide|r"))
        if ns.ResetListOffset then ns.ResetListOffset() end
        if ns.RefreshUI then ns.RefreshUI() end
    elseif cmd == "toast" then
        ns.db.autoToast = not ns.db.autoToast
        ns.Print("Discovery Toasts: " .. (ns.db.autoToast and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
        if ns.RefreshOptionsPanel then ns.RefreshOptionsPanel() end
    elseif cmd == "quests" or cmd == "trackquests" then
        ns.db.trackQuests = (ns.db.trackQuests == false)
        ns.Print("Automatic Quest Tracking: " .. (ns.db.trackQuests and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
        if ns.RefreshOptionsPanel then ns.RefreshOptionsPanel() end
    elseif cmd == "options" or cmd == "config" or cmd == "settings" then
        if ns.ShowMainFrame then
            ns.ShowMainFrame()
        elseif ns.ToggleMainFrame and ChronicleWeaverMainFrame and not ChronicleWeaverMainFrame:IsShown() then
            ns.ToggleMainFrame()
        end
        if ns.ToggleOptionsPanel then
            ns.ToggleOptionsPanel(true)
        end
    elseif cmd == "ledger" or cmd == "books" then
        if ns.ShowMainFrame then
            ns.ShowMainFrame()
        elseif ns.ToggleMainFrame and ChronicleWeaverMainFrame and not ChronicleWeaverMainFrame:IsShown() then
            ns.ToggleMainFrame()
        end
        if ns.ToggleLedgerPanel then
            ns.ToggleLedgerPanel("LEDGER")
        end
    elseif cmd == "export" then
        if ns.ShowMainFrame then
            ns.ShowMainFrame()
        elseif ns.ToggleMainFrame and ChronicleWeaverMainFrame and not ChronicleWeaverMainFrame:IsShown() then
            ns.ToggleMainFrame()
        end
        if ns.ToggleLedgerPanel then
            ns.ToggleLedgerPanel("EXPORT")
        end
    elseif cmd == "nearest" or cmd == "radar" then
        if ns.PinNearestMissingBook then
            ns.PinNearestMissingBook()
        end
    elseif cmd == "scan" then
        if ns.ScanActiveQuestLog then
            ns.ScanActiveQuestLog(true)
            ns.Print("Scanned your active Quest Log for chronicles.")
            if ns.RefreshUI then ns.RefreshUI() end
        elseif ns.ScanQuestLog then
            ns.ScanQuestLog(true)
            ns.Print("Scanned your active Quest Log for chronicles.")
            if ns.RefreshUI then ns.RefreshUI() end
        else
            ns.Print("Quest scanner engine not yet initialized.")
        end
    elseif cmd == "help" then
        ns.Print("Available Commands:")
        print("  |cffffd100/cw|r - Open/Close the Tome")
        print("  |cffffd100/cw options|r - Open General Options panel")
        print("  |cffffd100/cw ledger|r - Open Library Books Ledger & Checklist")
        print("  |cffffd100/cw export|r - Open Markdown & Lua Export tool")
        print("  |cffffd100/cw nearest|r - Pin the nearest uncollected Library Book")
        print("  |cffffd100/cw quests|r - Toggle automatic Quest Tracking")
        print("  |cffffd100/cw scan|r - Manually harvest lore from active Quest Log")
        print("  |cffffd100/cw theme|r - Toggle between Parchment & Dark modes")
        print("  |cffffd100/cw spoilers|r - Toggle Spoiler-Safe mode")
        print("  |cffffd100/cw scope|r - Toggle Account-Wide vs. Current Character entries")
        print("  |cffffd100/cw toast|r - Toggle Discovery Toast banners")
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
