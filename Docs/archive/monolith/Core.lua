local addonName, ns = ...

ns.events = {}
ns.frame = CreateFrame("Frame")

-- Default SavedVariables schema
local defaults = {
    spoilerFree = true,       -- Hide full lore text until discovered in-game
    autoToast = true,         -- Show toast banner when discovering new lore
    windowPos = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
    discovered = {},          -- [entryKey] = timestamp
    discoveredMeta = {},      -- [entryKey] = { char = "Name-Realm", faction = "Alliance"|"Horde", time = timestamp }
    notes = {},               -- [entryKey] = "Player's custom field note"
    books = {},               -- [bookKey] = harvested multi-page book & coordinate data
    quests = {},              -- [questKey] = harvested quest lore & dialog data
    items = {},               -- [itemKey] = harvested flavor-text relic & item data
    charFilter = "ALL",       -- "ALL" or "CURRENT"
    factionFilter = "ALL",    -- "ALL", "Alliance", "Horde", "Neutral"
}

-- Forever 16001 Guard: Values like UnitName() can be secret strings in protected contexts.
-- Never index a table, compare, or concatenate a secret value without guarding first!
function ns.IsSecret(val)
    return type(issecretvalue) == "function" and issecretvalue(val)
end

function ns.SafeString(val, fallback)
    if val == nil or ns.IsSecret(val) then
        return fallback or "Unknown"
    end
    return val
end

function ns.GetPlayerKey()
    local name = ns.SafeString(UnitName("player"), "Unknown")
    local realm = ns.SafeString(GetRealmName and GetRealmName(), "")
    if realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

function ns.GetPlayerFaction()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return ns.SafeString(faction, "Neutral")
end

function ns.Print(msg)
    print("|cffd4a85a[ChronicleWeaver]|r " .. tostring(msg))
end

-- Unlock a lore entry and trigger the UI toast if it's a first-time discovery
function ns.UnlockEntry(entryKey)
    if not ns.db or not entryKey or not ns.LoreByKey[entryKey] then return end

    local isNew = false
    if not ns.db.discovered[entryKey] then
        ns.db.discovered[entryKey] = time()
        isNew = true
    end

    ns.db.discoveredMeta = ns.db.discoveredMeta or {}
    if not ns.db.discoveredMeta[entryKey] then
        ns.db.discoveredMeta[entryKey] = {
            char = ns.GetPlayerKey(),
            faction = ns.GetPlayerFaction(),
            time = time(),
        }
    end

    local entry = ns.LoreByKey[entryKey]
    ns.currentContextKey = entryKey

    if (isNew or entry.category == "Book" or entry.category == "Quest") and ns.SelectEntry then
        ns.SelectEntry(entryKey)
    end

    if isNew and ns.db.autoToast and ns.ShowDiscoveryToast then
        ns.ShowDiscoveryToast(entry)
    end

    -- Clue Synthesis & Deduction Engine (Step 3.1)
    if isNew and ns.LoreSyntheses then
        for _, synth in ipairs(ns.LoreSyntheses) do
            if not ns.db.discovered[synth.key] and synth.requiredClues then
                local allMet = true
                for _, reqKey in ipairs(synth.requiredClues) do
                    if not ns.db.discovered[reqKey] then
                        allMet = false
                        break
                    end
                end

                if allMet then
                    ns.db.discovered[synth.key] = time()
                    if ns.db.autoToast and ns.ShowDiscoveryToast then
                        ns.ShowDiscoveryToast(synth, true)
                    end
                    ns.Print(string.format("Lore Deduction Synthesized: |cffc586c0%s|r!", synth.title))
                end
            end
        end
    end

    if ns.RefreshUI then
        ns.RefreshUI()
    end
end

-- Drop a native World Map waypoint pin for harvested books/plaques with coordinates
function ns.PinEntryToMap(entryKey)
    local entry = entryKey and ns.LoreByKey[entryKey]
    if not entry or not entry.mapID or not entry.x or entry.x <= 0 then
        ns.Print("No exact map coordinates recorded for this entry yet.")
        return
    end

    if C_Map and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(entry.mapID) then
        local point = UiMapPoint.CreateFromCoordinates(entry.mapID, entry.x, entry.y)
        C_Map.SetUserWaypoint(point)
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        ns.Print(string.format("Pinned |cffffd100%s|r to your World Map (%.1f, %.1f)!", entry.title, entry.x * 100, entry.y * 100))
    else
        ns.Print("Cannot place a waypoint inside an instance map.")
    end
end

-- Delete a harvested in-game book, quest, or relic from the Codex and SavedVariables
function ns.DeleteSavedBook(bookKey)
    if not ns.db or not bookKey then return end
    local isBook = ns.db.books and ns.db.books[bookKey]
    local isQuest = ns.db.quests and ns.db.quests[bookKey]
    local isItem = ns.db.items and ns.db.items[bookKey]
    if not isBook and not isQuest and not isItem then return end

    local bookTitle = (ns.LoreByKey and ns.LoreByKey[bookKey] and ns.LoreByKey[bookKey].title)
        or (isBook and ns.db.books[bookKey].title)
        or (isQuest and ns.db.quests[bookKey].title)
        or (isItem and ns.db.items[bookKey].title)
        or bookKey

    -- 1. Remove from SavedVariables
    if isBook then ns.db.books[bookKey] = nil end
    if isQuest then ns.db.quests[bookKey] = nil end
    if isItem then ns.db.items[bookKey] = nil end
    if ns.db.discovered then
        ns.db.discovered[bookKey] = nil
    end
    if ns.db.discoveredMeta then
        ns.db.discoveredMeta[bookKey] = nil
    end
    if ns.db.notes then
        ns.db.notes[bookKey] = nil
    end

    -- 2. Remove from runtime lore index
    if ns.LoreByKey then
        ns.LoreByKey[bookKey] = nil
    end
    if ns.LoreEntries then
        for i = #ns.LoreEntries, 1, -1 do
            if ns.LoreEntries[i].key == bookKey then
                table.remove(ns.LoreEntries, i)
                break
            end
        end
    end

    if ns.currentContextKey == bookKey then
        ns.currentContextKey = nil
    end

    ns.Print(string.format("Deleted harvested lore entry: |cffffd100%s|r", bookTitle))

    if ns.RefreshUI then
        ns.RefreshUI()
    end
end

-- Event Dispatcher
ns.frame:SetScript("OnEvent", function(self, event, ...)
    if ns.events[event] then
        ns.events[event](self, ...)
    end
end)

function ns.RegisterEvent(event, handler)
    ns.events[event] = handler
    ns.frame:RegisterEvent(event)
end

-- Strictly initialize SavedVariables inside ADDON_LOADED (never at file scope!)
ns.RegisterEvent("ADDON_LOADED", function(_, loadedAddon)
    if loadedAddon ~= addonName then return end

    ChronicleWeaverDB = ChronicleWeaverDB or {}
    for k, v in pairs(defaults) do
        if ChronicleWeaverDB[k] == nil then
            if type(v) == "table" then
                ChronicleWeaverDB[k] = CopyTable(v)
            else
                ChronicleWeaverDB[k] = v
            end
        end
    end
    ns.db = ChronicleWeaverDB

    -- 1. Index static LoreDB entries
    ns.BuildLoreIndex()

    -- 2. Check syntheses for already-discovered clues
    if ns.LoreSyntheses and ns.db.discovered then
        for _, synth in ipairs(ns.LoreSyntheses) do
            if not ns.db.discovered[synth.key] and synth.requiredClues then
                local allMet = true
                for _, reqKey in ipairs(synth.requiredClues) do
                    if not ns.db.discovered[reqKey] then
                        allMet = false
                        break
                    end
                end
                if allMet then
                    ns.db.discovered[synth.key] = time()
                end
            end
        end
    end

    -- 3. Hydrate all previously harvested in-game books, quests, and relics into the Codex
    ns.db.books = ns.db.books or {}
    for bookKey, bookData in pairs(ns.db.books) do
        if ns.RegisterSavedBookInCodex then
            ns.RegisterSavedBookInCodex(bookKey, bookData)
        end
    end

    ns.db.quests = ns.db.quests or {}
    for questKey, questData in pairs(ns.db.quests) do
        if ns.RegisterSavedQuestInCodex then
            ns.RegisterSavedQuestInCodex(questKey, questData)
        end
    end

    ns.db.items = ns.db.items or {}
    for itemKey, itemData in pairs(ns.db.items) do
        if ns.RegisterSavedItemInCodex then
            ns.RegisterSavedItemInCodex(itemKey, itemData)
        end
    end
end)

-- Minimap Addon Compartment Callbacks (Native in 16001)
function ChronicleWeaver_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        ns.db.spoilerFree = not ns.db.spoilerFree
        ns.Print("Spoiler-Safe Mode: " .. (ns.db.spoilerFree and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
        if ns.RefreshUI then ns.RefreshUI() end
    else
        if ns.ToggleMainFrame then ns.ToggleMainFrame() end
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

-- Slash Commands (/cw or /lorecodex)
SLASH_CHRONICLEWEAVER1 = "/cw"
SLASH_CHRONICLEWEAVER2 = "/lorecodex"
SlashCmdList["CHRONICLEWEAVER"] = function(msg)
    local cmd = strtrim(msg or ""):lower()
    if cmd == "spoilers" then
        ns.db.spoilerFree = not ns.db.spoilerFree
        ns.Print("Spoiler-Safe Mode: " .. (ns.db.spoilerFree and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
        if ns.RefreshUI then ns.RefreshUI() end
    elseif cmd == "toast" then
        ns.db.autoToast = not ns.db.autoToast
        ns.Print("Discovery Toasts: " .. (ns.db.autoToast and "|cff4cd964Enabled|r" or "|cffff3b30Disabled|r"))
    elseif cmd == "scan" or cmd == "quests" then
        if ns.ScanQuestLog then
            ns.ScanQuestLog()
            ns.Print("Scanned your active Quest Log for chronicles.")
            if ns.RefreshUI then ns.RefreshUI() end
        end
    else
        if ns.ToggleMainFrame then ns.ToggleMainFrame() end
    end
end