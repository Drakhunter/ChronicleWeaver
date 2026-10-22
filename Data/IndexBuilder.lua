-- =========================================================================
-- Data/IndexBuilder.lua
-- Compiles raw static data and hydrates SavedVariables into runtime lookup maps.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

-- -------------------------------------------------------------------------
-- Helper: Format Multi-Page Book Story
-- -------------------------------------------------------------------------
local function BuildBookStory(pages)
    if type(pages) == "string" then
        return pages
    end
    if type(pages) ~= "table" then
        return ""
    end

    local pageNums = {}
    for pNum in pairs(pages) do
        table.insert(pageNums, pNum)
    end
    table.sort(pageNums)

    if #pageNums == 0 then
        return ""
    elseif #pageNums == 1 then
        return pages[pageNums[1]] or ""
    end

    local parts = {}
    for _, pNum in ipairs(pageNums) do
        table.insert(parts, string.format("|cffd4a85a[Page %d]|r\n%s", pNum, pages[pNum] or ""))
    end
    return table.concat(parts, "\n\n")
end

-- -------------------------------------------------------------------------
-- Upsert Single Runtime Lore Entry
-- -------------------------------------------------------------------------
function ns.UpsertRuntimeEntry(entryObj)
    if not entryObj or not entryObj.key then return end

    -- Normalize default properties
    entryObj.category = entryObj.category or "Book"
    entryObj.title    = entryObj.title or entryObj.key
    entryObj.era      = entryObj.era or (entryObj.category == "Dossier" and "Lore Dossier") or "Classic & Forever"
    entryObj.icon     = entryObj.icon or (ns.CategoryIcons and ns.CategoryIcons[entryObj.category]) or "Interface\\Icons\\INV_Misc_Book_09"
    entryObj.zone     = entryObj.zone or "Unknown"
    entryObj.related  = entryObj.related or {}
    entryObj.summary  = entryObj.summary or ""
    entryObj.story    = entryObj.story or ""

    local existing = ns.LoreByKey and ns.LoreByKey[entryObj.key]
    if existing then
        for k, v in pairs(entryObj) do
            existing[k] = v
        end
        entryObj = existing
    else
        ns.LoreEntries = ns.LoreEntries or {}
        ns.LoreByKey = ns.LoreByKey or {}
        table.insert(ns.LoreEntries, entryObj)
        ns.LoreByKey[entryObj.key] = entryObj
    end

    -- Fast trigger indexing
    if entryObj.triggerType == "ZONE" and entryObj.triggerValue then
        ns.LoreByZone = ns.LoreByZone or {}
        ns.LoreByZone[tostring(entryObj.triggerValue):lower()] = entryObj.key
    elseif entryObj.triggerType == "NPC" and entryObj.triggerValue then
        ns.LoreByNPC = ns.LoreByNPC or {}
        ns.LoreByNPC[tostring(entryObj.triggerValue):lower()] = entryObj.key
    elseif entryObj.triggerType == "ITEM" and entryObj.triggerValue then
        ns.LoreByItem = ns.LoreByItem or {}
        local id = tonumber(entryObj.triggerValue) or entryObj.triggerValue
        ns.LoreByItem[id] = entryObj.key
    end

    if entryObj.category == "Dossier" then
        ns.Dossiers = ns.Dossiers or {}
        local found = false
        for _, d in ipairs(ns.Dossiers) do
            if d.key == entryObj.key then
                found = true
                break
            end
        end
        if not found then
            table.insert(ns.Dossiers, entryObj)
        end
    end

    if entryObj.zone and entryObj.zone ~= "" and entryObj.zone ~= "Unknown" then
        ns.LoreListByZone = ns.LoreListByZone or {}
        local zk = entryObj.zone:lower()
        ns.LoreListByZone[zk] = ns.LoreListByZone[zk] or {}
        local inList = false
        for _, k in ipairs(ns.LoreListByZone[zk]) do
            if k == entryObj.key then
                inList = true
                break
            end
        end
        if not inList then
            table.insert(ns.LoreListByZone[zk], entryObj.key)
        end
    end

    return entryObj
end

-- -------------------------------------------------------------------------
-- Hydration Wrappers for Scanners (with WeaveEngine auto-highlighter integration)
-- -------------------------------------------------------------------------
function ns.RegisterSavedBookInCodex(bookKey, bookData)
    if not bookKey or not bookData then return end
    local rawStory = BuildBookStory(bookData.pages or bookData.text)
    local wovenStory = rawStory
    local relatedKeys = {}
    if ns.WeaveTextConnections then
        wovenStory, relatedKeys = ns.WeaveTextConnections(rawStory)
    end

    local firstPage = ""
    if type(bookData.pages) == "table" and bookData.pages[1] then
        firstPage = bookData.pages[1]
    elseif type(bookData.text) == "string" then
        firstPage = bookData.text
    end
    local snippet = (firstPage:len() > 140) and (firstPage:sub(1, 137) .. "...") or firstPage

    local entry = {
        key         = bookKey,
        category    = "Book",
        title       = bookData.title or "Archived Tome",
        era         = "In-Game Harvest",
        zone        = bookData.zone or "Azeroth",
        mapID       = bookData.mapID,
        x           = bookData.x,
        y           = bookData.y,
        character   = bookData.character,
        characters  = bookData.characters,
        faction     = bookData.faction,
        isHarvested = true,
        icon        = bookData.icon or (ns.CategoryIcons and ns.CategoryIcons.Book) or "Interface\\Icons\\INV_Misc_Book_09",
        summary     = snippet ~= "" and snippet or ("In-game book or monument recorded in " .. (bookData.zone or "Azeroth")),
        story       = wovenStory,
        related     = relatedKeys,
    }
    return ns.UpsertRuntimeEntry(entry)
end

function ns.RegisterSavedQuestInCodex(questKey, questData)
    if not questKey or not questData then return end
    local storyParts = {}
    if questData.giver and questData.giver ~= "" then
        table.insert(storyParts, "|cffd4a85aQuest Giver:|r " .. questData.giver)
    end
    if questData.description and questData.description ~= "" then
        table.insert(storyParts, questData.description)
    elseif questData.detailText and questData.detailText ~= "" then
        table.insert(storyParts, questData.detailText)
    end
    if questData.objectiveProse and questData.objectiveProse ~= "" then
        table.insert(storyParts, "|cffd4a85aObjective:|r " .. questData.objectiveProse)
    end
    if questData.resolution and questData.resolution ~= "" then
        table.insert(storyParts, "|cffffd100[Resolution]|r\n" .. questData.resolution)
    end

    local rawStory = table.concat(storyParts, "\n\n")
    local wovenStory = rawStory
    local relatedKeys = {}
    if ns.WeaveTextConnections then
        wovenStory, relatedKeys = ns.WeaveTextConnections(rawStory)
    end

    local desc = questData.description or questData.detailText or ""
    local snippet = (desc:len() > 140) and (desc:sub(1, 137) .. "...") or desc

    local entry = {
        key         = questKey,
        category    = "Quest",
        title       = questData.title or "Quest Narrative",
        era         = "In-Game Harvest",
        zone        = questData.zone or "Azeroth",
        mapID       = questData.mapID,
        x           = questData.x,
        y           = questData.y,
        giver       = questData.giver,
        character   = questData.character,
        characters  = questData.characters,
        faction     = questData.faction,
        isHarvested = true,
        icon        = questData.icon or (ns.CategoryIcons and ns.CategoryIcons.Quest) or "Interface\\Icons\\INV_Misc_Note_01",
        summary     = snippet ~= "" and snippet or ("Quest narrative recorded from " .. (questData.giver or questData.zone or "an Azerothian traveler")),
        story       = wovenStory,
        related     = relatedKeys,
    }
    return ns.UpsertRuntimeEntry(entry)
end

function ns.RegisterSavedItemInCodex(itemKey, itemData)
    if not itemKey or not itemData then return end
    local flavor = itemData.flavorText or itemData.story or ""
    local wovenStory = flavor
    local relatedKeys = {}
    if ns.WeaveTextConnections and flavor ~= "" then
        wovenStory, relatedKeys = ns.WeaveTextConnections(flavor)
    end

    local entry = {
        key         = itemKey,
        category    = "Relic",
        title       = itemData.title or itemData.name or "Ancient Relic",
        era         = "In-Game Harvest",
        zone        = itemData.zone or "Azeroth",
        mapID       = itemData.mapID,
        x           = itemData.x,
        y           = itemData.y,
        itemID      = itemData.itemID,
        character   = itemData.character,
        characters  = itemData.characters,
        faction     = itemData.faction,
        isHarvested = true,
        icon        = itemData.icon or (ns.CategoryIcons and ns.CategoryIcons.Relic) or "Interface\\Icons\\INV_Misc_Gem_Variety_01",
        summary     = flavor ~= "" and flavor or ("Curated relic discovered in " .. (itemData.zone or "Azeroth")),
        story       = wovenStory,
        related     = relatedKeys,
    }
    return ns.UpsertRuntimeEntry(entry)
end

function ns.RegisterSavedGossipInCodex(gossipKey, gossipData)
    if not gossipKey or not gossipData then return end
    local text = gossipData.text or ""
    local wovenStory = text
    local relatedKeys = {}
    if ns.WeaveTextConnections and text ~= "" then
        wovenStory, relatedKeys = ns.WeaveTextConnections(text)
    end

    local snippet = (text:len() > 140) and (text:sub(1, 137) .. "...") or text
    local entry = {
        key         = gossipKey,
        category    = "NPC",
        title       = gossipData.title or (gossipData.npc and ("Dialogue: " .. gossipData.npc)) or "Field Dialogue",
        era         = "In-Game Harvest",
        zone        = gossipData.zone or "Azeroth",
        mapID       = gossipData.mapID,
        x           = gossipData.x,
        y           = gossipData.y,
        npc         = gossipData.npc,
        character   = gossipData.character,
        characters  = gossipData.characters,
        faction     = gossipData.faction,
        isHarvested = true,
        icon        = gossipData.icon or (ns.CategoryIcons and ns.CategoryIcons.Gossip) or "Interface\\Icons\\INV_Misc_Note_02",
        summary     = snippet ~= "" and snippet or ("Field dialogue recorded from " .. (gossipData.npc or "local resident")),
        story       = wovenStory,
        related     = relatedKeys,
    }
    return ns.UpsertRuntimeEntry(entry)
end

-- -------------------------------------------------------------------------
-- Build Complete Lore Index
-- Compiles raw static data & hydrates all SavedVariables records
-- -------------------------------------------------------------------------
function ns.BuildLoreIndex()
    ns.LoreEntries = {}
    ns.LoreByKey = {}
    ns.LoreByZone = {}
    ns.LoreByNPC = {}
    ns.LoreByItem = {}
    ns.LoreListByZone = {}
    ns.Dossiers = {}

    -- 1. Ingest Classic static lore
    if ns.RawLoreClassic then
        for _, entry in ipairs(ns.RawLoreClassic) do
            ns.UpsertRuntimeEntry(entry)
        end
    end

    -- 2. Ingest Forever Classic+ static lore
    if ns.RawLoreForever then
        for _, entry in ipairs(ns.RawLoreForever) do
            ns.UpsertRuntimeEntry(entry)
        end
    end

    -- 3. Ingest Topic Dossiers
    if ns.RawLoreTopics then
        for _, topic in ipairs(ns.RawLoreTopics) do
            ns.UpsertRuntimeEntry(topic)
        end
    end

    -- 4. Hydrate saved books from SavedVariables
    if ns.db and ns.db.books then
        for bookKey, bookData in pairs(ns.db.books) do
            ns.RegisterSavedBookInCodex(bookKey, bookData)
        end
    end

    -- 5. Hydrate saved quests from SavedVariables
    if ns.db and ns.db.quests then
        for questKey, questData in pairs(ns.db.quests) do
            ns.RegisterSavedQuestInCodex(questKey, questData)
        end
    end

    -- 6. Hydrate saved relics/items from SavedVariables
    if ns.db and ns.db.items then
        for itemKey, itemData in pairs(ns.db.items) do
            ns.RegisterSavedItemInCodex(itemKey, itemData)
        end
    end

    -- 7. Hydrate saved gossip dialogues from SavedVariables
    if ns.db and ns.db.gossip then
        for gossipKey, gossipData in pairs(ns.db.gossip) do
            ns.RegisterSavedGossipInCodex(gossipKey, gossipData)
        end
    end

    -- 8. Trigger backlink graph and topic clustering if WeaveEngine is loaded
    if ns.RebuildLoreWeb then
        ns.RebuildLoreWeb()
    end

    if ns.SendMessage then
        ns.SendMessage("CODEX_INDEX_BUILT")
    end
end
