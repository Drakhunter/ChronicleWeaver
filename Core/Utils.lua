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
function ns.SetMapPin(mapID, x, y, title)
    if not mapID or not x or not y or x <= 0 then
        ns.Print("No exact map coordinates recorded for this entry yet.")
        return false
    end

    if C_Map and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapID) then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        C_Map.SetUserWaypoint(point)
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        ns.Print(string.format("Pinned |cffffd100%s|r to your World Map (%.1f, %.1f)!", title or "Lore Location", x * 100, y * 100))
        return true
    else
        ns.Print("Cannot place a waypoint inside an instance or unmapped zone.")
        return false
    end
end

function ns.PinEntryToMap(entryKey)
    local entry = entryKey and ns.LoreByKey and ns.LoreByKey[entryKey]
    if not entry then
        ns.Print("No exact map coordinates recorded for this entry yet.")
        return false
    end
    return ns.SetMapPin(entry.mapID, entry.x, entry.y, entry.title or entryKey)
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

ns.DeleteHarvestedEntry = ns.DeleteSavedEntry
-- -------------------------------------------------------------------------
-- Per-Character Discovery & Ownership Helpers
-- -------------------------------------------------------------------------
function ns.IsKeyUnlockedByChar(entryKey, playerKey)
    if not entryKey or not ns.db then return false end
    playerKey = playerKey or ns.GetPlayerKey()

    local meta = ns.db.discoveredMeta and ns.db.discoveredMeta[entryKey]
    if meta then
        if meta.char == playerKey then
            return true
        end
        if type(meta.chars) == "table" and meta.chars[playerKey] ~= nil then
            return true
        end
    end

    local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
    if entry then
        if entry.character == playerKey then
            return true
        end
        if type(entry.characters) == "table" and entry.characters[playerKey] then
            return true
        end
    end

    local savedRec = (ns.db.quests and ns.db.quests[entryKey])
        or (ns.db.books and ns.db.books[entryKey])
        or (ns.db.items and ns.db.items[entryKey])
        or (ns.db.gossip and ns.db.gossip[entryKey])
    if type(savedRec) == "table" then
        if savedRec.character == playerKey then
            return true
        end
        if type(savedRec.characters) == "table" and savedRec.characters[playerKey] then
            return true
        end
    end

    return false
end

function ns.IsEntryForCurrentCharacter(entry)
    if not entry then return false end
    if type(entry) == "string" then
        entry = (ns.LoreByKey and ns.LoreByKey[entry]) or { key = entry }
    end
    if not entry.key then return false end

    local playerKey = ns.GetPlayerKey()
    if ns.IsKeyUnlockedByChar(entry.key, playerKey) then
        return true
    end

    if entry.category == "Dossier" then
        local clues = (ns.GetDossierClues and ns.GetDossierClues(entry.key))
            or (ns.DossierClues and ns.DossierClues[entry.key])
            or entry.related
        if clues and #clues > 0 then
            for _, cKey in ipairs(clues) do
                if ns.IsKeyUnlockedByChar(cKey, playerKey) then
                    return true
                end
            end
        end
    end

    return false
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

    if ns.db and ns.db.charFilter == "CURRENT" then
        return ns.IsEntryForCurrentCharacter(entry)
    end

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

    local now = time()
    local playerKey = ns.GetPlayerKey()
    local playerFaction = ns.GetPlayerFaction()

    local isNew = false
    if not ns.db.discovered[entryKey] then
        ns.db.discovered[entryKey] = now
        isNew = true
    end

    ns.db.discoveredMeta = ns.db.discoveredMeta or {}
    local meta = ns.db.discoveredMeta[entryKey]
    if type(meta) ~= "table" then
        meta = {
            char = playerKey,
            faction = playerFaction,
            time = now,
            chars = {},
        }
        ns.db.discoveredMeta[entryKey] = meta
    end
    meta.chars = meta.chars or {}
    if meta.char and not meta.chars[meta.char] then
        meta.chars[meta.char] = meta.time or now
    end
    meta.chars[playerKey] = meta.chars[playerKey] or now

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

-- -------------------------------------------------------------------------
-- Deliverable Lore Books & Library Book Intelligence (WoW: Forever & Classic)
-- -------------------------------------------------------------------------
ns.LibraryBookCatalog = {
    { itemID = 203754, title = "Archmage Antonidas: The Unabridged Autobiography", zone = "Ironforge", subzone = "Hall of Explorers", mapID = 1455, x = 0.757, y = 0.105, faction = "Alliance" },
    { itemID = 203755, title = "Archmage Theocritus' Research Journal", zone = "Elwynn Forest", subzone = "Tower of Azora", mapID = 1429, x = 0.654, y = 0.701, faction = "Neutral" },
    { itemID = 207972, title = "The Lessons of Ta'zo", zone = "Orgrimmar", subzone = "Valley of Spirits", mapID = 1454, x = 0.386, y = 0.784, faction = "Horde" },
    { itemID = 208185, title = "The Apothecary's Metaphysical Primer", zone = "Tirisfal Glades", subzone = "Brill Alchemy Shop", mapID = 1420, x = 0.594, y = 0.523, faction = "Horde" },
    { itemID = 208800, title = "Baxtan: On Destructive Magics", zone = "The Barrens", subzone = "Ratchet Workshop", mapID = 1413, x = 0.627, y = 0.363, faction = "Neutral" },
    { itemID = 208860, title = "Rumi of Gnomeregan: The Collected Works", zone = "Westfall", subzone = "Sentinel Hill Inn", mapID = 1436, x = 0.527, y = 0.538, faction = "Neutral" },
    { itemID = 209843, title = "Nar'thalas Almanac, Vol. 74", zone = "Darkshore", subzone = "Ruins of Mathystra", mapID = 1439, x = 0.596, y = 0.222, faction = "Neutral" },
    { itemID = 209844, title = "The Dalaran Digest, Vol. 23", zone = "Silverpine Forest", subzone = "Ambermill", mapID = 1421, x = 0.635, y = 0.631, faction = "Neutral" },
    { itemID = 209845, title = "Bewitchments and Glamours", zone = "Westfall", subzone = "Moonbrook", mapID = 1436, x = 0.454, y = 0.705, faction = "Neutral" },
    { itemID = 209847, title = "Arcanic Systems Manual", zone = "The Barrens", subzone = "Sludge Fen Oil Rig", mapID = 1413, x = 0.563, y = 0.088, faction = "Neutral" },
    { itemID = 209848, title = "Goaz Scrolls", zone = "Wetlands", subzone = "Whelgar's Excavation Site", mapID = 1437, x = 0.336, y = 0.479, faction = "Neutral" },
    { itemID = 209849, title = "Crimes Against Anatomy", zone = "Duskwood", subzone = "Dawning Wood Catacombs", mapID = 1431, x = 0.166, y = 0.285, faction = "Neutral" },
    { itemID = 209850, title = "Runes of the Sorcerer-Kings", zone = "Loch Modan", subzone = "Mo'grosh Stronghold", mapID = 1432, x = 0.775, y = 0.141, faction = "Neutral" },
    { itemID = 209851, title = "Fury of the Land", zone = "Stonetalon Mountains", subzone = "Grimtotem Post", mapID = 1442, x = 0.744, y = 0.857, faction = "Neutral" },
    { itemID = 210177, title = "Ataeric: On Arcane Curiosities", zone = "Silverpine Forest", subzone = "The Sepulcher Crypt", mapID = 1421, x = 0.434, y = 0.412, faction = "Horde" },
    { itemID = 213165, title = "Secrets of the Dreamers", zone = "The Barrens", subzone = "Wailing Caverns Outer Cave", mapID = 1413, x = 0.460, y = 0.365, faction = "Neutral" },
    { itemID = 215814, title = "Geomancy: The Stone-Cold Truth", zone = "Thousand Needles", subzone = "Darkcloud Pinnacle", mapID = 1441, x = 0.344, y = 0.400, faction = "Neutral" },
    { itemID = 215815, title = "Defensive Magics 101", zone = "Alterac Mountains", subzone = "Gallows' Corner Tower", mapID = 1416, x = 0.484, y = 0.576, faction = "Neutral" },
    { itemID = 215816, title = "A Web of Lies: Debunking Myths and Legends", zone = "Arathi Highlands", subzone = "Witherbark Village", mapID = 1417, x = 0.736, y = 0.652, faction = "Neutral" },
    { itemID = 215817, title = "Demons and You", zone = "Desolace", subzone = "Thunder Axe Fortress", mapID = 1443, x = 0.551, y = 0.262, faction = "Neutral" },
    { itemID = 215822, title = "RwlRwlRwlRwl!", zone = "Dustwallow Marsh", subzone = "North of Witch Hill", mapID = 1445, x = 0.572, y = 0.208, faction = "Neutral" },
    { itemID = 220345, title = "Sanguine Sorcery", zone = "Swamp of Sorrows", subzone = "Temple of Atal'Hakkar Terrace", mapID = 1435, x = 0.701, y = 0.518, faction = "Neutral" },
    { itemID = 220346, title = "Legends of the Tidesages", zone = "Tanaris", subzone = "Lost Rigger Cove", mapID = 1446, x = 0.727, y = 0.478, faction = "Neutral" },
    { itemID = 220347, title = "The Liminal and the Arcane", zone = "Feralas", subzone = "Ruins of Isildien", mapID = 1444, x = 0.510, y = 0.160, faction = "Neutral" },
    { itemID = 220348, title = "Everyday Etiquette", zone = "Azshara", subzone = "Haldarr Encampment", mapID = 1447, x = 0.208, y = 0.620, faction = "Neutral" },
    { itemID = 220349, title = "Stonewrought Design", zone = "Burning Steppes", subzone = "Blackrock Mountain", mapID = 1428, x = 0.290, y = 0.289, faction = "Neutral" },
    { itemID = 220350, title = "Venomous Journeys", zone = "The Hinterlands", subzone = "Shadra'alor", mapID = 1425, x = 0.360, y = 0.728, faction = "Neutral" },
    { itemID = 220352, title = "A Mind of Metal", zone = "Searing Gorge", subzone = "Central Searing Gorge", mapID = 1427, x = 0.378, y = 0.493, faction = "Neutral" },
    { itemID = 220353, title = "Conjurer's Codex", zone = "Blasted Lands", subzone = "Dreadmaul Hold", mapID = 1419, x = 0.554, y = 0.322, faction = "Neutral" },
    { itemID = 228132, title = "Undead Potatoes", zone = "Western Plaguelands", subzone = "Felstone Field", mapID = 1422, x = 0.383, y = 0.546, faction = "Neutral" },
    { itemID = 228133, title = "Magma or Lava?", zone = "Burning Steppes", subzone = "Blackrock Mountain", mapID = 1428, x = 0.296, y = 0.282, faction = "Neutral" },
    { itemID = 228135, title = "A Study of the Light", zone = "Eastern Plaguelands", subzone = "Light's Hope Chapel", mapID = 1423, x = 0.718, y = 0.482, faction = "Neutral" },
    { itemID = 228138, title = "The Knight and the Lady", zone = "Eastern Plaguelands", subzone = "Lake Mereldar", mapID = 1423, x = 0.473, y = 0.423, faction = "Neutral" },
    { itemID = 228140, title = "Scourge: Undead Menace or Misunderstood?", zone = "Eastern Plaguelands", subzone = "Stratholme Gate Bridge", mapID = 1423, x = 0.266, y = 0.145, faction = "Neutral" },
    { itemID = 228141, title = "Necromancy 101", zone = "Western Plaguelands", subzone = "Caer Darrow", mapID = 1422, x = 0.694, y = 0.728, faction = "Neutral" },
}

ns.LibraryBookIDs = {}
ns.LibraryBookByID = {}
ns.LibraryBookTitles = {
    ["mummies: a guide to the unsavory undead"] = true,
    ["scourge undead: menace or misunderstood?"] = true,
    ["magma or lava"] = true,
    ["nar'thalas almanac"] = true,
}
for _, book in ipairs(ns.LibraryBookCatalog) do
    ns.LibraryBookIDs[book.itemID] = book.title
    ns.LibraryBookByID[book.itemID] = book
    ns.LibraryBookTitles[book.title:lower()] = true
end

local LIBRARY_TARGET_ALLIANCE = {
    npc = "Garion Wendell",
    location = "Wizard's Sanctum (Mage Quarter), Stormwind City",
    mapID = 1453,
    x = 0.490,
    y = 0.863,
    coords = "49.0, 86.3",
    faction = "Alliance",
}

local LIBRARY_TARGET_HORDE = {
    npc = "Owen Thadd",
    location = "Magic Quarter, Undercity",
    mapID = 1458,
    x = 0.740,
    y = 0.325,
    coords = "74.0, 32.5",
    faction = "Horde",
}

local BURNING_STEPPES_LIBRAM_TARGET = {
    npc = "Mathredis Firestar",
    location = "Flame Crest, Burning Steppes",
    mapID = 1428,
    x = 0.650,
    y = 0.236,
    coords = "65.0, 23.6",
    faction = "Neutral",
}

local DIRE_MAUL_LIBRAM_TARGET = {
    npc = "Lorekeeper Lydros",
    location = "The Athenaeum, Dire Maul",
    coords = "Dire Maul North/West",
    faction = "Neutral",
}

local function MakeClassicDeliverable(title, categoryLabel, rewardNote, target)
    return {
        title = title,
        isLibraryBook = false,
        categoryLabel = categoryLabel,
        rewardNote = rewardNote,
        primary = target,
    }
end

ns.ClassicDeliverableItems = {
    [6283] = MakeClassicDeliverable(
        "The Book of Ur",
        "Classic Quest Tome",
        "Turn in for the Horde Shadowfang Keep quest 'The Book of Ur'.",
        {
            npc = "Keeper Bel'dugur",
            location = "The Apothecarium, Undercity",
            mapID = 1458,
            x = 0.536,
            y = 0.546,
            coords = "53.6, 54.6",
            faction = "Horde",
        }
    ),
    [11732] = MakeClassicDeliverable("Libram of Rumination", "Classic Libram", "Turn in with required reagents for Lesser Arcanum of Rumination (+150 Mana).", BURNING_STEPPES_LIBRAM_TARGET),
    [11733] = MakeClassicDeliverable("Libram of Constitution", "Classic Libram", "Turn in with required reagents for Lesser Arcanum of Constitution (+100 Health).", BURNING_STEPPES_LIBRAM_TARGET),
    [11734] = MakeClassicDeliverable("Libram of Tenacity", "Classic Libram", "Turn in with required reagents for Lesser Arcanum of Tenacity (+125 Armor).", BURNING_STEPPES_LIBRAM_TARGET),
    [11736] = MakeClassicDeliverable("Libram of Resilience", "Classic Libram", "Turn in with required reagents for Lesser Arcanum of Resilience (+20 Fire Resistance).", BURNING_STEPPES_LIBRAM_TARGET),
    [11737] = MakeClassicDeliverable("Libram of Voracity", "Classic Libram", "Turn in with required reagents for Lesser Arcanum of Voracity (+8 to a chosen stat).", BURNING_STEPPES_LIBRAM_TARGET),
    [18332] = MakeClassicDeliverable("Libram of Rapidity", "Dire Maul Libram", "Turn in with required reagents for Arcanum of Rapidity (+1% Haste).", DIRE_MAUL_LIBRAM_TARGET),
    [18333] = MakeClassicDeliverable("Libram of Focus", "Dire Maul Libram", "Turn in with required reagents for Arcanum of Focus (+8 Spell Damage & Healing).", DIRE_MAUL_LIBRAM_TARGET),
    [18334] = MakeClassicDeliverable("Libram of Protection", "Dire Maul Libram", "Turn in with required reagents for Arcanum of Protection (+1% Dodge).", DIRE_MAUL_LIBRAM_TARGET),
}

function ns.GetItemDeliveryInfo(itemID, flavorText, itemName)
    local numericID = tonumber(itemID)
    local isLibrary = false

    if numericID and ns.LibraryBookIDs[numericID] then
        isLibrary = true
    elseif type(flavorText) == "string" and flavorText ~= "" and not ns.IsSecret(flavorText) then
        local fl = flavorText:lower()
        if fl:find("library's collection", 1, true) or fl:find("fine addition to any library", 1, true) then
            isLibrary = true
        end
    end

    if not isLibrary and type(itemName) == "string" and itemName ~= "" and not ns.IsSecret(itemName) then
        local cleanName = itemName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$"):lower()
        if ns.LibraryBookTitles[cleanName] then
            isLibrary = true
        end
    end

    if isLibrary then
        local faction = ns.GetPlayerFaction and ns.GetPlayerFaction() or "Neutral"
        local primary = (faction == "Horde") and LIBRARY_TARGET_HORDE or LIBRARY_TARGET_ALLIANCE
        local secondary = (faction == "Horde") and LIBRARY_TARGET_ALLIANCE or LIBRARY_TARGET_HORDE
        return {
            isLibraryBook = true,
            categoryLabel = "WoW: Forever Library Book",
            primary = primary,
            secondary = secondary,
            rewardNote = "Turn in individually for XP, silver & a Comprehension Charm; 10/20/25 books unlock Friend of the Library gear.",
        }
    end

    if numericID and ns.ClassicDeliverableItems[numericID] then
        return ns.ClassicDeliverableItems[numericID]
    end

    return nil
end

function ns.AddDeliveryHintToTooltip(tooltip, deliveryInfo)
    if ns.db and ns.db.showDeliveryHints == false then return end
    if not tooltip or not tooltip.AddLine or not deliveryInfo or not deliveryInfo.primary then return end
    local p = deliveryInfo.primary
    local coordStr = p.coords and (" |cff88ccff(" .. p.coords .. ")|r") or ""
    tooltip:AddLine(
        string.format("|cff4cd964Deliver To:|r |cffffd100%s|r - %s%s", p.npc, p.location, coordStr),
        1, 1, 1, true
    )
    if deliveryInfo.secondary then
        local s = deliveryInfo.secondary
        local sCoord = s.coords and (" (" .. s.coords .. ")") or ""
        tooltip:AddLine(
            string.format("%s Turn-In: %s - %s%s", s.faction or "Other", s.npc, s.location, sCoord),
            0.65, 0.72, 0.80, true
        )
    end
    if deliveryInfo.rewardNote and deliveryInfo.rewardNote ~= "" then
        tooltip:AddLine(deliveryInfo.rewardNote, 0.75, 0.85, 0.68, true)
    end
end

function ns.FormatDeliveryDirectiveText(deliveryInfo)
    if not deliveryInfo or not deliveryInfo.primary then return "" end
    local p = deliveryInfo.primary
    local pCoord = p.coords and (" (" .. p.coords .. ")") or ""
    local lines = {
        "|cffffd100[Archivist Delivery Directive]|r",
        string.format("Deliver To (%s): %s - %s%s", p.faction or "Neutral", p.npc, p.location, pCoord),
    }
    if deliveryInfo.secondary then
        local s = deliveryInfo.secondary
        local sCoord = s.coords and (" (" .. s.coords .. ")") or ""
        table.insert(lines, string.format("Counterpart (%s): %s - %s%s", s.faction or "Other", s.npc, s.location, sCoord))
    end
    if deliveryInfo.rewardNote and deliveryInfo.rewardNote ~= "" then
        table.insert(lines, "Rewards: " .. deliveryInfo.rewardNote)
    end
    return table.concat(lines, "\n")
end

-- -------------------------------------------------------------------------
-- Library Books Progress, Nearest Missing Finder & Cartography Helpers
-- -------------------------------------------------------------------------
function ns.GetBagItemIDSet()
    local bagSet = {}
    if not C_Container or not C_Container.GetContainerNumSlots then
        return bagSet
    end
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots and not ns.IsSecret(numSlots) and numSlots > 0 then
            for slot = 1, numSlots do
                local itemID = C_Container.GetContainerItemID(bag, slot)
                if itemID and not ns.IsSecret(itemID) and type(itemID) == "number" then
                    bagSet[itemID] = true
                end
            end
        end
    end
    return bagSet
end

function ns.IsBookEligibleForPlayer(book)
    if not book or not book.faction or book.faction == "Neutral" then
        return true
    end
    local pFaction = ns.GetPlayerFaction and ns.GetPlayerFaction() or "Neutral"
    if pFaction == "Neutral" then return true end
    return book.faction == pFaction
end

function ns.GetLibraryBookStatus(itemID, bagSet)
    if not itemID then return "MISSING" end
    if ns.db and ns.db.completedLibraryBooks and ns.db.completedLibraryBooks[itemID] then
        return "TURNED_IN"
    end
    bagSet = bagSet or ns.GetBagItemIDSet()
    if bagSet[itemID] then
        return "IN_BAG"
    end
    local key = "item:" .. itemID
    if (ns.db and ns.db.items and ns.db.items[key])
        or (ns.db and ns.db.discovered and ns.db.discovered[key]) then
        return "COLLECTED"
    end
    return "MISSING"
end

function ns.GetLibraryProgressStats(filterMapID)
    local bagSet = ns.GetBagItemIDSet()
    local collected, inBag, total = 0, 0, 0
    for _, book in ipairs(ns.LibraryBookCatalog) do
        if ns.IsBookEligibleForPlayer(book) and (not filterMapID or book.mapID == filterMapID) then
            total = total + 1
            local status = ns.GetLibraryBookStatus(book.itemID, bagSet)
            if status == "TURNED_IN" or status == "COLLECTED" then
                collected = collected + 1
            elseif status == "IN_BAG" then
                collected = collected + 1
                inBag = inBag + 1
            end
        end
    end
    return collected, inBag, total
end

function ns.PinNearestMissingBook(targetMapID, targetZoneName)
    local bagSet = ns.GetBagItemIDSet()
    local _, _, playerMapID, px, py = ns.GetPlayerLocationData()
    local refMapID = targetMapID or playerMapID
    local lowerZone = targetZoneName and targetZoneName:lower() or nil

    local function FindBestBook(matchFn)
        local bestBook, bestDist = nil, math.huge
        for _, book in ipairs(ns.LibraryBookCatalog) do
            if ns.IsBookEligibleForPlayer(book) and book.mapID and book.x and book.y then
                local status = ns.GetLibraryBookStatus(book.itemID, bagSet)
                if status == "MISSING" and matchFn(book) then
                    local dist = 1
                    if refMapID and book.mapID == refMapID and px and px > 0 then
                        local dx = book.x - px
                        local dy = book.y - py
                        dist = (dx * dx) + (dy * dy)
                    end
                    if dist < bestDist then
                        bestDist = dist
                        bestBook = book
                    end
                end
            end
        end
        return bestBook
    end

    local chosen = nil
    if targetMapID then
        chosen = FindBestBook(function(b) return b.mapID == targetMapID end)
    elseif lowerZone then
        chosen = FindBestBook(function(b) return b.zone and b.zone:lower() == lowerZone end)
    elseif playerMapID then
        chosen = FindBestBook(function(b) return b.mapID == playerMapID end)
    end

    if not chosen and not targetMapID and not lowerZone then
        chosen = FindBestBook(function() return true end)
    end

    if chosen then
        local label = string.format("%s (%s - %s)", chosen.title, chosen.zone, chosen.subzone or "")
        ns.SetMapPin(chosen.mapID, chosen.x, chosen.y, label)
        return chosen
    end

    -- Fallback: nearest undiscovered coordinate-tagged lore entry in LoreEntries
    if ns.LoreEntries then
        local bestEntry, bestDist = nil, math.huge
        for _, entry in ipairs(ns.LoreEntries) do
            if entry.mapID and entry.x and entry.x > 0 and not (ns.IsEntryUnlocked and ns.IsEntryUnlocked(entry)) then
                local matches = (not targetMapID and not lowerZone)
                    or (targetMapID and entry.mapID == targetMapID)
                    or (lowerZone and entry.zone and entry.zone:lower() == lowerZone)
                if matches then
                    local dist = 1
                    if refMapID and entry.mapID == refMapID and px and px > 0 then
                        local dx = entry.x - px
                        local dy = entry.y - py
                        dist = (dx * dx) + (dy * dy)
                    end
                    if dist < bestDist then
                        bestDist = dist
                        bestEntry = entry
                    end
                end
            end
        end
        if bestEntry then
            ns.SetMapPin(bestEntry.mapID, bestEntry.x, bestEntry.y, bestEntry.title or bestEntry.key)
            return bestEntry
        end
    end

    ns.Print("No missing Library Books or unvisited coordinate chronicles found in this scope!")
    return nil
end

-- -------------------------------------------------------------------------
-- Chronological Timeline Classifier
-- -------------------------------------------------------------------------
function ns.GetChronologicalEraBucket(entry)
    if not entry then return "IV. Classic Azeroth" end
    if entry.isHarvested then
        if entry.deliveryInfo and entry.deliveryInfo.isLibraryBook then
            return "V. Forever Classic+ Awakenings"
        end
        return "VI. Personal Field Harvests"
    end

    local text = ((entry.era or "") .. " " .. (entry.title or "") .. " " .. (entry.zone or "")):lower()
    if text:find("first age", 1, true) or text:find("titan", 1, true) or text:find("shaper", 1, true)
        or text:find("uldaman", 1, true) or text:find("un'goro", 1, true) then
        return "I. First Age: Titan Ordering & Primordial Kalimdor"
    elseif text:find("highborne", 1, true) or text:find("troll", 1, true) or text:find("gurubashi", 1, true)
        or text:find("shen'dralas", 1, true) or text:find("dire maul", 1, true) or text:find("drowned city", 1, true) then
        return "II. Ancient Empires: Highborne & Troll Civilizations"
    elseif text:find("first war", 1, true) or text:find("second war", 1, true) or text:find("third war", 1, true)
        or text:find("lordaeron", 1, true) or text:find("scarlet", 1, true) or text:find("karazhan", 1, true)
        or text:find("three hammers", 1, true) then
        return "III. The Three Wars & Fall of Lordaeron"
    elseif (entry.era and entry.era:find("Forever", 1, true))
        or text:find("zephras", 1, true) or text:find("riverglades", 1, true)
        or text:find("krol'dok", 1, true) or text:find("alcaz", 1, true)
        or text:find("blackmaw", 1, true) or text:find("library", 1, true) then
        return "V. Forever Classic+ Awakenings"
    end
    return "IV. Classic Azeroth"
end

-- -------------------------------------------------------------------------
-- Clickable Inline Hyperlink Injector
-- -------------------------------------------------------------------------
function ns.InjectHyperlinks(text)
    if not text or type(text) ~= "string" or text == "" then
        return text or ""
    end
    local candidates = ns.BuildWeavableCandidates and ns.BuildWeavableCandidates()
    if not candidates or #candidates == 0 then
        return text
    end

    local phraseToKey = {}
    for _, cand in ipairs(candidates) do
        local lp = cand.phrase:lower()
        if not phraseToKey[lp] then
            phraseToKey[lp] = cand.key
        end
    end

    local isSpoilerFree = (ns.db and ns.db.spoilerFree == true)
    return text:gsub("(|c%x%x%x%x%x%x%x%x)(%[(.-)%])|r", function(color, bracketed, word)
        local targetKey = phraseToKey[word:lower()]
        if not targetKey then
            return nil
        end
        if isSpoilerFree then
            local targetEntry = ns.LoreByKey and ns.LoreByKey[targetKey]
            if not targetEntry or not (ns.IsEntryUnlocked and ns.IsEntryUnlocked(targetEntry)) then
                return nil
            end
        end
        return color .. "|Hcw:" .. targetKey .. "|h" .. bracketed .. "|h|r"
    end)
end

-- -------------------------------------------------------------------------
-- Markdown & Lua Export Serializers
-- -------------------------------------------------------------------------
function ns.StripWoWEscapes(text)
    if not text or type(text) ~= "string" then return "" end
    local clean = text:gsub("|H[^|]*|h", ""):gsub("|h", "")
    clean = clean:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return clean
end

function ns.ExportEntryToMarkdown(entryKey)
    local entry = entryKey and ns.LoreByKey and ns.LoreByKey[entryKey]
    if not entry then
        return "# No Chronicle Selected\n\nSelect an entry from the Codex first."
    end
    local lines = {
        "# " .. ns.StripWoWEscapes(entry.title or entry.key),
        "",
        string.format("- **Category:** %s", entry.category or "Lore"),
        string.format("- **Zone:** %s", entry.zone or "Azeroth"),
        string.format("- **Era:** %s", entry.era or "Classic & Forever"),
        string.format("- **Faction:** %s", entry.faction or "Neutral"),
    }
    if entry.mapID and entry.x and entry.x > 0 then
        table.insert(lines, string.format("- **Coordinates:** Map %d (%.1f, %.1f)", entry.mapID, entry.x * 100, entry.y * 100))
    end
    if entry.summary and entry.summary ~= "" then
        table.insert(lines, "")
        table.insert(lines, "## Summary")
        table.insert(lines, ns.StripWoWEscapes(entry.summary))
    end
    if entry.story and entry.story ~= "" then
        table.insert(lines, "")
        table.insert(lines, "## Chronicle")
        table.insert(lines, ns.StripWoWEscapes(entry.story))
    end
    local note = ns.db and ns.db.notes and ns.db.notes[entry.key]
    if note and note ~= "" then
        table.insert(lines, "")
        table.insert(lines, "## Personal Field Notes")
        table.insert(lines, note)
    end
    return table.concat(lines, "\n")
end

local function SerializeLuaString(val)
    return string.format("%q", tostring(val or ""))
end

function ns.ExportHarvestedToLua()
    if not ns.db then return "-- ChronicleWeaverDB not initialized" end
    local out = {
        "-- ChronicleWeaver Harvested Lore Export",
        "ChronicleWeaverExport = {",
        "    books = {",
    }
    for k, rec in pairs(ns.db.books or {}) do
        if type(rec) == "table" then
            table.insert(out, string.format("        [%s] = { title = %s, zone = %s, x = %.3f, y = %.3f },",
                SerializeLuaString(k), SerializeLuaString(rec.title), SerializeLuaString(rec.zone), rec.x or 0, rec.y or 0))
        end
    end
    table.insert(out, "    },")
    table.insert(out, "    quests = {")
    for k, rec in pairs(ns.db.quests or {}) do
        if type(rec) == "table" then
            table.insert(out, string.format("        [%s] = { title = %s, questID = %s, zone = %s, giver = %s },",
                SerializeLuaString(k), SerializeLuaString(rec.title), tostring(rec.questID or "nil"),
                SerializeLuaString(rec.zone), SerializeLuaString(rec.giver)))
        end
    end
    table.insert(out, "    },")
    table.insert(out, "    items = {")
    for k, rec in pairs(ns.db.items or {}) do
        if type(rec) == "table" then
            table.insert(out, string.format("        [%s] = { itemID = %s, title = %s, zone = %s, flavorText = %s },",
                SerializeLuaString(k), tostring(rec.itemID or "nil"), SerializeLuaString(rec.title),
                SerializeLuaString(rec.zone), SerializeLuaString(rec.flavorText)))
        end
    end
    table.insert(out, "    },")
    table.insert(out, "    gossip = {")
    for k, rec in pairs(ns.db.gossip or {}) do
        if type(rec) == "table" then
            table.insert(out, string.format("        [%s] = { npc = %s, zone = %s, text = %s },",
                SerializeLuaString(k), SerializeLuaString(rec.npc), SerializeLuaString(rec.zone), SerializeLuaString(rec.text)))
        end
    end
    table.insert(out, "    },")
    table.insert(out, "}")
    return table.concat(out, "\n")
end

-- -------------------------------------------------------------------------
-- Party / Guild Addon Comms Lore Sync (CW_LORE)
-- -------------------------------------------------------------------------
function ns.BroadcastEntryToPeers(entryKey)
    if ns.db and ns.db.addonSync == false then
        ns.Print("Addon Comms Lore Sync is disabled in Options.")
        return false
    end
    local entry = entryKey and ns.LoreByKey and ns.LoreByKey[entryKey]
    if not entry then
        ns.Print("Select a chronicle to share.")
        return false
    end
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
        ns.Print("Addon messaging API is unavailable in this client context.")
        return false
    end

    local channel = nil
    if IsInRaid and IsInRaid() then
        channel = "RAID"
    elseif IsInGroup and IsInGroup() then
        channel = "PARTY"
    elseif IsInGuild and IsInGuild() then
        channel = "GUILD"
    end

    if not channel then
        ns.Print("Join a Party, Raid, or Guild to share chronicles with peers.")
        return false
    end

    local safeTitle = (entry.title or entry.key):gsub("|", "-")
    local safeZone = (entry.zone or "Azeroth"):gsub("|", "-")
    local payload = string.format("SHARE|%s|%s|%s|%s", entry.key, safeTitle, entry.category or "Lore", safeZone)
    if #payload > 250 then
        payload = payload:sub(1, 250)
    end
    C_ChatInfo.SendAddonMessage("CW_LORE", payload, channel)
    ns.Print(string.format("Shared |cffffd100%s|r with %s peers via ChronicleWeaver Sync.", entry.title or entry.key, channel))
    return true
end
