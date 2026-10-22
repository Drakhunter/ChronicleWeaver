-- =========================================================================
-- Core/Utils.lua
-- Secret-value guards, player location, map waypoints, favorites & entry deletion.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

-- -------------------------------------------------------------------------
-- Secret-Value Guards (Interface 16001)
-- In restricted contexts, values such as UnitName or item fields can be
-- tagged as secret. Always guard against comparisons, indexing or concatenations.
-- -------------------------------------------------------------------------
local issecretvalue = issecretvalue

function ns.IsSecret(val)
    return issecretvalue ~= nil and issecretvalue(val) == true
end

function ns.SafeString(val, fallback)
    if val == nil or ns.IsSecret(val) then
        return fallback or ""
    end
    return tostring(val)
end

-- -------------------------------------------------------------------------
-- Chat & Formatting Helpers
-- -------------------------------------------------------------------------
function ns.Colorize(hex, text)
    return "|cff" .. hex .. tostring(text) .. "|r"
end

function ns.Print(msg, ...)
    if select("#", ...) > 0 then
        msg = string.format(msg, ...)
    end
    print("|cffd4a85a[" .. addonName .. "]|r " .. tostring(msg))
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

-- -------------------------------------------------------------------------
-- Safe Location Query
-- Returns: zone (string), subzone (string), mapID (number|nil), x (number), y (number)
-- -------------------------------------------------------------------------
function ns.GetPlayerLocationData()
    local zone = ns.SafeString(GetRealZoneText and GetRealZoneText() or (GetZoneText and GetZoneText()), "Unknown Zone")
    local subzone = ns.SafeString(GetSubZoneText and GetSubZoneText(), "")
    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local x, y = 0, 0

    if mapID and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos and pos.GetXY then
            local px, py = pos:GetXY()
            if px and py and not ns.IsSecret(px) and not ns.IsSecret(py) then
                x = px
                y = py
            end
        end
    end

    return zone, subzone, mapID, x, y
end

-- -------------------------------------------------------------------------
-- Map Pinning via UiMapPoint & SuperTracking
-- -------------------------------------------------------------------------
function ns.PinEntryToMap(entryKey)
    local entry = entryKey and ns.LoreByKey and ns.LoreByKey[entryKey]
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
        ns.Print(string.format("Pinned |cffffd100%s|r to your World Map (%.1f, %.1f)!", entry.title or entryKey, entry.x * 100, entry.y * 100))
    else
        ns.Print("Cannot place a waypoint inside an instance or unmapped zone.")
    end
end

-- -------------------------------------------------------------------------
-- Favorite Toggle (...)
-- -------------------------------------------------------------------------
function ns.ToggleFavorite(entryKey)
    if not ns.db or not entryKey then return end
    ns.db.favorites = ns.db.favorites or {}

    local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
    local title = entry and entry.title or entryKey

    if ns.db.favorites[entryKey] then
        ns.db.favorites[entryKey] = nil
        ns.Print(string.format("Removed |cffffd100%s|r from Favorites.", title))
    else
        ns.db.favorites[entryKey] = true
        ns.Print(string.format("Added |cffffd100%s|r to Favorites (*).", title))
    end

    if ns.SendMessage then
        ns.SendMessage("FAVORITES_UPDATED", entryKey, ns.db.favorites[entryKey])
    end
    if ns.RefreshUI then
        ns.RefreshUI()
    end
end

-- -------------------------------------------------------------------------
-- Delete Harvested Entry
-- Removes saved Book, Quest, Relic, or Gossip entry from SavedVariables,
-- runtime indexes, triggers weave rebuild, and refreshes UI.
-- -------------------------------------------------------------------------
function ns.DeleteSavedEntry(entryKey)
    if not ns.db or not entryKey then return end

    local isBook = ns.db.books and ns.db.books[entryKey]
    local isQuest = ns.db.quests and ns.db.quests[entryKey]
    local isItem = ns.db.items and ns.db.items[entryKey]
    local isGossip = ns.db.gossip and ns.db.gossip[entryKey]

    if not isBook and not isQuest and not isItem and not isGossip then
        ns.Print("This entry is core static lore and cannot be deleted.")
        return
    end

    local entryTitle = (ns.LoreByKey and ns.LoreByKey[entryKey] and ns.LoreByKey[entryKey].title)
        or (isBook and type(isBook) == "table" and isBook.title)
        or (isQuest and type(isQuest) == "table" and isQuest.title)
        or (isItem and type(isItem) == "table" and isItem.title)
        or (isGossip and type(isGossip) == "table" and isGossip.title)
        or entryKey

    -- 1. Remove from SavedVariables
    if isBook then ns.db.books[entryKey] = nil end
    if isQuest then ns.db.quests[entryKey] = nil end
    if isItem then ns.db.items[entryKey] = nil end
    if isGossip then ns.db.gossip[entryKey] = nil end

    if ns.db.discovered then ns.db.discovered[entryKey] = nil end
    if ns.db.discoveredMeta then ns.db.discoveredMeta[entryKey] = nil end
    if ns.db.favorites then ns.db.favorites[entryKey] = nil end
    if ns.db.notes then ns.db.notes[entryKey] = nil end

    -- 2. Remove from runtime lore index
    if ns.LoreByKey then
        ns.LoreByKey[entryKey] = nil
    end
    if ns.LoreEntries then
        for i = #ns.LoreEntries, 1, -1 do
            if ns.LoreEntries[i].key == entryKey then
                table.remove(ns.LoreEntries, i)
                break
            end
        end
    end

    if ns.currentContextKey == entryKey then
        ns.currentContextKey = nil
    end

    -- 3. Rebuild weaves/backlinks/dossiers
    if ns.RebuildLoreWeb then
        ns.RebuildLoreWeb()
    end

    ns.Print(string.format("Deleted harvested lore entry: |cffffd100%s|r", entryTitle))

    -- 4. Notify UI
    if ns.SendMessage then
        ns.SendMessage("ENTRY_DELETED", entryKey)
    end
    if ns.RefreshUI then
        ns.RefreshUI()
    end
end
-- -------------------------------------------------------------------------
-- Entry Discovery & Unlock State
-- -------------------------------------------------------------------------
function ns.IsEntryUnlocked(entry)
    if not entry then return false end
    if type(entry) == "string" then
        entry = (ns.LoreByKey and ns.LoreByKey[entry]) or { key = entry }
    end
    if not entry.key then return false end

    -- Dossier unlock rule:
    -- A Dossier is unlocked if ns.db.discovered[entry.key] is true
    -- OR if it has at least 1 discovered clue in its Dossier clue list.
    if entry.category == "Dossier" then
        if ns.db and ns.db.discovered and ns.db.discovered[entry.key] ~= nil then
            return true
        end
        local clues = (ns.GetDossierClues and ns.GetDossierClues(entry.key))
            or (ns.DossierClues and ns.DossierClues[entry.key])
            or entry.related
        if clues and #clues > 0 and ns.db and ns.db.discovered then
            for _, cKey in ipairs(clues) do
                if ns.db.discovered[cKey] ~= nil then
                    return true
                end
            end
        end
        return false
    end

    return ns.db and ns.db.discovered and (ns.db.discovered[entry.key] ~= nil)
end

-- -------------------------------------------------------------------------
-- Entry Discovery & Unlock
-- -------------------------------------------------------------------------
function ns.UnlockEntry(entryKey)
    if not ns.db or not entryKey then return end
    local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
    if not entry then return end

    local isNew = false
    if not ns.db.discovered[entryKey] then
        ns.db.discovered[entryKey] = time()
        isNew = true
        ns.db.discoveredMeta = ns.db.discoveredMeta or {}
        ns.db.discoveredMeta[entryKey] = {
            char = ns.GetPlayerKey(),
            faction = ns.GetPlayerFaction(),
            time = time(),
        }
    end

    ns.currentContextKey = entryKey

    if isNew and ns.db.autoToast and ns.ShowDiscoveryToast then
        ns.ShowDiscoveryToast(entry)
    end

    if ns.SendMessage then
        ns.SendMessage("ENTRY_UNLOCKED", entry, isNew)
    end

    if ns.RefreshUI then
        ns.RefreshUI()
    end
end
