local addonName, ns = ...

-- ==========================================
-- 1. ZONE & SUBZONE SCANNER
-- ==========================================
local function CheckCurrentZone()
    if not ns.LoreByZone then return end

    local zone = ns.SafeString(GetRealZoneText(), "")
    local subzone = ns.SafeString(GetSubZoneText(), "")

    local subKey = subzone ~= "" and ns.LoreByZone[subzone:lower()]
    local zoneKey = zone ~= "" and ns.LoreByZone[zone:lower()]

    if subKey then
        ns.UnlockEntry(subKey)
    elseif zoneKey then
        ns.UnlockEntry(zoneKey)
    end
end

ns.RegisterEvent("PLAYER_ENTERING_WORLD", CheckCurrentZone)
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", CheckCurrentZone)
ns.RegisterEvent("ZONE_CHANGED", CheckCurrentZone)
ns.RegisterEvent("ZONE_CHANGED_INDOORS", CheckCurrentZone)

-- ==========================================
-- 2. TARGET NPC SCANNER (SECRET-VALUE GUARDED)
-- ==========================================
ns.RegisterEvent("PLAYER_TARGET_CHANGED", function()
    if not ns.LoreByNPC then return end

    local exists = UnitExists("target")
    if ns.IsSecret(exists) or not exists then return end

    local targetName = UnitName("target")
    if not targetName or ns.IsSecret(targetName) then return end

    local npcKey = ns.LoreByNPC[targetName:lower()]
    if npcKey then
        ns.UnlockEntry(npcKey)
    end
end)

-- ==========================================
-- 3. ASYNCHRONOUS ITEM LORE LOOKUP
-- ==========================================
function ns.InspectItemLore(itemID)
    if not itemID or not ns.LoreByItem then return end
    local entryKey = ns.LoreByItem[itemID]
    if not entryKey then return end

    local itemName = C_Item.GetItemInfo(itemID)
    if itemName and not ns.IsSecret(itemName) then
        ns.UnlockEntry(entryKey)
    else
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

ns.RegisterEvent("ITEM_DATA_LOAD_RESULT", function(_, itemID, success)
    if not success or not ns.LoreByItem then return end
    local entryKey = ns.LoreByItem[itemID]
    if entryKey then
        ns.UnlockEntry(entryKey)
    end
end)

-- ==========================================
-- 4. AUTOMATIC BAG SCANNER FOR RELICS (Step 2.3)
-- ==========================================
local function ScanBagsForRelics()
    if not ns.LoreByItem or not C_Container or not C_Container.GetContainerNumSlots then return end

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots and not ns.IsSecret(numSlots) and numSlots > 0 then
            for slot = 1, numSlots do
                local itemID = C_Container.GetContainerItemID(bag, slot)
                if itemID and not ns.IsSecret(itemID) and type(itemID) == "number" and ns.LoreByItem[itemID] then
                    ns.InspectItemLore(itemID)
                end
            end
        end
    end
end

ns.RegisterEvent("BAG_UPDATE_DELAYED", ScanBagsForRelics)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", ScanBagsForRelics)

-- ==========================================
-- 5. MODERN TOOLTIP HOOKS (NPC & ITEM)
-- ==========================================
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    -- NPC Tooltip Hook
    if Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip ~= GameTooltip or not ns.LoreByNPC or not ns.db then return end

            local name = tooltip:GetUnit()
            if not name or ns.IsSecret(name) then return end

            local entryKey = ns.LoreByNPC[name:lower()]
            if not entryKey then return end

            local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
            if not entry then return end
            local isDiscovered = ns.db.discovered and (ns.db.discovered[entryKey] ~= nil)

            tooltip:AddLine(" ")
            tooltip:AddLine("|cffd4a85a[ChronicleWeaver Lore]|r")
            if isDiscovered or not ns.db.spoilerFree then
                tooltip:AddLine(entry.summary, 0.9, 0.85, 0.7, true)
            else
                tooltip:AddLine("Target this character to unlock their chronicle entry.", 0.6, 0.6, 0.6, true)
            end
        end)
    end

    -- Relic / Item Tooltip Hook (Step 2.3 & In-Game Flavor Relic Harvester)
    if Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if not tooltip or not ns.db then return end

            local itemID = data and data.id
            if not itemID and tooltip.GetItem then
                local _, itemLink = tooltip:GetItem()
                if itemLink and not ns.IsSecret(itemLink) and C_Item and C_Item.GetItemInfoInstant then
                    itemID = C_Item.GetItemInfoInstant(itemLink)
                end
            end

            if not itemID or ns.IsSecret(itemID) or type(itemID) ~= "number" then return end

            -- (a) Unlock matching static or previously registered ns.LoreByItem item on hover
            local entryKey = ns.LoreByItem and ns.LoreByItem[itemID]
            if entryKey then
                ns.InspectItemLore(itemID)
                local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
                if entry and entry.summary then
                    tooltip:AddLine(" ")
                    tooltip:AddLine("|cffd4a85a[ChronicleWeaver Lore]|r")
                    tooltip:AddLine(entry.summary, 0.9, 0.85, 0.7, true)
                end
                return
            end

            -- (b) Check for quoted flavor-text line to harvest dynamically as a Relic
            local flavor = nil
            if data and data.lines then
                for _, lineData in ipairs(data.lines) do
                    local lineText = lineData.leftText
                    if lineText and not ns.IsSecret(lineText) and type(lineText) == "string" then
                        local clean = lineText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$")
                        if clean then
                            local m = clean:match('^"([^"]+)"$') or clean:match('^ ([^ ]+) $')
                            if m and #m > 1 then
                                flavor = m
                                break
                            end
                        end
                    end
                end
            end

            if not flavor and tooltip.GetName then
                local tName = tooltip:GetName()
                local numLines = tooltip.NumLines and tooltip:NumLines()
                if tName and numLines and not ns.IsSecret(numLines) then
                    for i = 1, numLines do
                        local fs = _G[tName .. "TextLeft" .. i]
                        if fs and fs.GetText then
                            local lineText = fs:GetText()
                            if lineText and not ns.IsSecret(lineText) and type(lineText) == "string" then
                                local clean = lineText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$")
                                if clean then
                                    local m = clean:match('^"([^"]+)"$') or clean:match('^ ([^ ]+) $')
                                    if m and #m > 1 then
                                        flavor = m
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if flavor then
                local itemKey = "item:" .. itemID
                ns.db.items = ns.db.items or {}
                local isNew = (ns.db.items[itemKey] == nil)

                local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)
                itemName = ns.SafeString(itemName, nil)
                if not itemName and data and data.lines and data.lines[1] and data.lines[1].leftText then
                    itemName = ns.SafeString(data.lines[1].leftText, nil)
                end
                itemName = itemName or ("Item #" .. tostring(itemID))

                local icon = itemTexture or (C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or 134400

                local itemRecord = ns.db.items[itemKey] or {
                    itemID = itemID,
                    title = itemName,
                    icon = icon,
                    flavorText = flavor,
                    zone = ns.SafeString(GetRealZoneText(), "Unknown Zone"),
                    character = ns.GetPlayerKey(),
                    faction = ns.GetPlayerFaction(),
                }
                itemRecord.title = itemName
                itemRecord.icon = icon
                itemRecord.flavorText = flavor
                itemRecord.character = itemRecord.character or ns.GetPlayerKey()
                itemRecord.faction = itemRecord.faction or ns.GetPlayerFaction()
                ns.db.items[itemKey] = itemRecord

                if ns.RegisterSavedItemInCodex then
                    ns.RegisterSavedItemInCodex(itemKey, itemRecord)
                end
                ns.UnlockEntry(itemKey)

                if isNew then
                    ns.Print(string.format("Harvested flavor relic: |cffffd100%s|r (\"%s\")", itemName, flavor))
                end

                tooltip:AddLine(" ")
                tooltip:AddLine("|cffd4a85a[ChronicleWeaver Relic]|r")
                tooltip:AddLine('"' .. flavor .. '"', 0.9, 0.85, 0.7, true)
            end
        end)
    end
end

-- ==========================================
-- 6. MULTI-PAGE BOOK, SCROLL & PLAQUE HARVESTER
-- ==========================================
function ns.WeaveTextConnections(rawText)
    if not rawText or ns.IsSecret(rawText) then return "", {} end

    local wovenText = rawText
    local matchedKeys = {}
    local seen = {}

    for _, entry in ipairs(ns.LoreEntries) do
        if entry.category ~= "Book" and entry.category ~= "Quest" and entry.triggerValue and type(entry.triggerValue) == "string" then
            local keyword = entry.triggerValue
            if #keyword >= 4 and wovenText:lower():find(keyword:lower(), 1, true) then
                if not seen[entry.key] then
                    seen[entry.key] = true
                    table.insert(matchedKeys, entry.key)
                end
                wovenText = wovenText:gsub(
                    "(" .. keyword .. ")",
                    "|cffffd100[%1]|r"
                )
            end
        end
    end

    return wovenText, matchedKeys
end

function ns.RegisterSavedBookInCodex(bookKey, bookData)
    local fullPages = {}
    local maxPage = bookData.maxPage or 1
    for p = 1, maxPage do
        if bookData.pages[p] then
            table.insert(fullPages, string.format("|cffd4a85a--- Page %d ---|r\n%s", p, bookData.pages[p]))
        end
    end

    local combinedRaw = table.concat(fullPages, "\n\n")
    local wovenStory, relatedKeys = ns.WeaveTextConnections(combinedRaw)

    local locString = (bookData.subzone and bookData.subzone ~= "")
        and (bookData.zone .. " (" .. bookData.subzone .. ")")
        or (bookData.zone or "Unknown Zone")
    local coordString = (bookData.x and bookData.x > 0)
        and string.format(" at %.1f, %.1f", bookData.x * 100, bookData.y * 100)
        or ""

    local entryObj = {
        key = bookKey,
        category = "Book",
        triggerType = "BOOK",
        triggerValue = bookData.title,
        title = bookData.title,
        era = "In-Game Text (" .. (bookData.pageCount or 1) .. "p)",
        summary = "Discovered in " .. locString .. coordString,
        story = wovenStory,
        related = relatedKeys,
        mapID = bookData.mapID,
        x = bookData.x,
        y = bookData.y,
        character = bookData.character,
        faction = bookData.faction,
    }

    if not ns.LoreByKey[bookKey] then
        table.insert(ns.LoreEntries, entryObj)
    else
        for i, existing in ipairs(ns.LoreEntries) do
            if existing.key == bookKey then
                ns.LoreEntries[i] = entryObj
                break
            end
        end
    end
    ns.LoreByKey[bookKey] = entryObj
end

local function CaptureItemText()
    if not ns.db then return end
    ns.db.books = ns.db.books or {}

    local rawTitle = ItemTextGetItem()
    if not rawTitle or rawTitle == "" or ns.IsSecret(rawTitle) then
        if ItemTextFrameTitleText and ItemTextFrameTitleText.GetText then
            rawTitle = ItemTextFrameTitleText:GetText()
        end
    end
    if not rawTitle or rawTitle == "" or ns.IsSecret(rawTitle) then
        if GetTitleText then
            rawTitle = GetTitleText()
        end
    end
    if not rawTitle or rawTitle == "" or ns.IsSecret(rawTitle) then
        if UnitExists("target") then
            rawTitle = UnitName("target")
        end
    end
    if not rawTitle or rawTitle == "" or ns.IsSecret(rawTitle) then
        if GameTooltip and GameTooltipTextLeft1 and GameTooltipTextLeft1.GetText then
            rawTitle = GameTooltipTextLeft1:GetText()
        end
    end

    local title = ns.SafeString(rawTitle, nil)
    if not title or title == "" then return end

    local rawPageText = ItemTextGetText()
    if (not rawPageText or rawPageText == "" or ns.IsSecret(rawPageText)) and ItemTextPageText and ItemTextPageText.GetText then
        rawPageText = ItemTextPageText:GetText()
    end
    local pageText = ns.SafeString(rawPageText, nil)

    if not pageText or pageText == "" then
        -- Retry after 0.15s if ItemTextFrame is still open
        if ItemTextFrame and ItemTextFrame:IsShown() and not ns._retryingItemText then
            ns._retryingItemText = true
            C_Timer.After(0.15, function()
                ns._retryingItemText = false
                CaptureItemText()
            end)
        end
        return
    end

    local pageNum = ItemTextGetPage() or 1
    if ns.IsSecret(pageNum) then pageNum = 1 end

    local bookKey = "book:" .. title
    local zone = ns.SafeString(GetRealZoneText(), "Unknown Zone")
    local subzone = ns.SafeString(GetSubZoneText(), "")

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local x, y = 0, 0
    if mapID and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos and not ns.IsSecret(pos) then
            x, y = pos:GetXY()
        end
    end

    local record = ns.db.books[bookKey] or {
        title = title,
        zone = zone,
        subzone = subzone,
        mapID = mapID,
        x = x,
        y = y,
        pages = {},
        maxPage = 1,
        pageCount = 0,
        character = ns.GetPlayerKey(),
        faction = ns.GetPlayerFaction(),
    }
    record.character = record.character or ns.GetPlayerKey()
    record.faction = record.faction or ns.GetPlayerFaction()

    local isNewPage = not record.pages[pageNum]
    if isNewPage then
        record.pageCount = (record.pageCount or 0) + 1
    end
    record.pages[pageNum] = pageText
    if pageNum > (record.maxPage or 1) then
        record.maxPage = pageNum
    end

    ns.db.books[bookKey] = record

    ns.RegisterSavedBookInCodex(bookKey, record)
    ns.UnlockEntry(bookKey)

    if isNewPage then
        ns.Print(string.format("Harvested page %d of book |cffffd100%s|r!", pageNum, title))
    end
end

ns.RegisterEvent("ITEM_TEXT_READY", CaptureItemText)
ns.RegisterEvent("ITEM_TEXT_BEGIN", CaptureItemText)
ns.RegisterEvent("ITEM_TEXT_TRANSLATION", CaptureItemText)

-- World Object & Gossip Lore Harvester (for books/plaques that open GossipFrame)
local function CaptureGossipLore()
    if not ns.db then return end
    ns.db.books = ns.db.books or {}

    local rawTitle = (UnitExists("npc") and UnitName("npc"))
        or (UnitExists("target") and UnitName("target"))
        or (GossipFrameTitleText and GossipFrameTitleText.GetText and GossipFrameTitleText:GetText())
    local title = ns.SafeString(rawTitle, nil)
    if not title or title == "" then return end

    local rawText = nil
    if C_GossipInfo and C_GossipInfo.GetText then
        rawText = C_GossipInfo.GetText()
    elseif GetGossipText then
        rawText = GetGossipText()
    end
    local text = ns.SafeString(rawText, nil)
    if not text or text == "" or #text < 15 then return end

    local titleLower = title:lower()
    local isLore = titleLower:find("book")
        or titleLower:find("tome")
        or titleLower:find("dummies")
        or titleLower:find("scroll")
        or titleLower:find("plaque")
        or titleLower:find("tablet")
        or titleLower:find("diary")
        or titleLower:find("journal")
        or titleLower:find("letter")
        or titleLower:find("manifesto")
        or titleLower:find("chronicle")
        or titleLower:find("history")
        or titleLower:find("record")
        or titleLower:find("inscription")
        or titleLower:find("compendium")

    if isLore then
        local bookKey = "book:" .. title
        local zone = ns.SafeString(GetRealZoneText(), "Unknown Zone")
        local subzone = ns.SafeString(GetSubZoneText(), "")

        local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        local x, y = 0, 0
        if mapID and C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos and not ns.IsSecret(pos) then
                x, y = pos:GetXY()
            end
        end

        local record = ns.db.books[bookKey] or {
            title = title,
            zone = zone,
            subzone = subzone,
            mapID = mapID,
            x = x,
            y = y,
            pages = {},
            maxPage = 1,
            pageCount = 0,
            character = ns.GetPlayerKey(),
            faction = ns.GetPlayerFaction(),
        }
        record.character = record.character or ns.GetPlayerKey()
        record.faction = record.faction or ns.GetPlayerFaction()

        local isNew = not record.pages[1]
        record.pages[1] = text
        record.pageCount = 1
        record.maxPage = 1
        ns.db.books[bookKey] = record

        ns.RegisterSavedBookInCodex(bookKey, record)
        ns.UnlockEntry(bookKey)

        if isNew then
            ns.Print(string.format("Harvested lore text from |cffffd100%s|r!", title))
        end
    end
end

ns.RegisterEvent("GOSSIP_SHOW", CaptureGossipLore)

-- ==========================================
-- 7. QUEST HARVESTER (DIALOGS & QUEST LOG)
-- ==========================================
function ns.RegisterSavedQuestInCodex(questKey, questData)
    local sections = {}
    if questData.npc and questData.npc ~= "" then
        table.insert(sections, string.format("|cffd4a85aQuest Giver:|r %s", questData.npc))
    end
    if questData.detailText and questData.detailText ~= "" then
        table.insert(sections, questData.detailText)
    end

    local combinedRaw = #sections > 0 and table.concat(sections, "\n\n") or (questData.detailText or "A recorded quest chronicle.")
    local wovenStory, relatedKeys = ns.WeaveTextConnections(combinedRaw)

    local locString = (questData.subzone and questData.subzone ~= "")
        and (questData.zone .. " (" .. questData.subzone .. ")")
        or (questData.zone or "Unknown Zone")
    local coordString = (questData.x and questData.x > 0)
        and string.format(" at %.1f, %.1f", questData.x * 100, questData.y * 100)
        or ""

    local entryObj = {
        key = questKey,
        category = "Quest",
        triggerType = "QUEST",
        triggerValue = questData.title,
        title = questData.title,
        era = questData.npc and ("Quest: " .. questData.npc) or (questData.zone and ("Quest: " .. questData.zone) or "Quest Tale"),
        summary = "Recorded in " .. locString .. coordString,
        story = wovenStory,
        related = relatedKeys,
        mapID = questData.mapID,
        x = questData.x,
        y = questData.y,
        character = questData.character,
        faction = questData.faction,
    }

    if not ns.LoreByKey[questKey] then
        table.insert(ns.LoreEntries, entryObj)
    else
        for i, existing in ipairs(ns.LoreEntries) do
            if existing.key == questKey then
                ns.LoreEntries[i] = entryObj
                break
            end
        end
    end
    ns.LoreByKey[questKey] = entryObj
end

local function CaptureQuestLore(event)
    if not ns.db then return end
    ns.db.quests = ns.db.quests or {}

    local rawTitle = GetTitleText and GetTitleText()
    local title = ns.SafeString(rawTitle, nil)
    if not title or title == "" then return end

    local questKey = "quest:" .. title
    local zone = ns.SafeString(GetRealZoneText(), "Unknown Zone")
    local subzone = ns.SafeString(GetSubZoneText(), "")

    local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local x, y = 0, 0
    if mapID and C_Map.GetPlayerMapPosition then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos and not ns.IsSecret(pos) then
            x, y = pos:GetXY()
        end
    end

    local rawNpc = (UnitExists("questnpc") and UnitName("questnpc")) or (UnitExists("target") and UnitName("target"))
    local npc = ns.SafeString(rawNpc, nil)

    local record = ns.db.quests[questKey] or {
        title = title,
        npc = npc,
        zone = zone,
        subzone = subzone,
        mapID = mapID,
        x = x,
        y = y,
        character = ns.GetPlayerKey(),
        faction = ns.GetPlayerFaction(),
    }
    record.character = record.character or ns.GetPlayerKey()
    record.faction = record.faction or ns.GetPlayerFaction()

    if npc and npc ~= "" then
        record.npc = npc
    end
    if x > 0 and y > 0 then
        record.mapID = mapID
        record.x = x
        record.y = y
    end

    if event == "QUEST_DETAIL" and GetQuestText then
        local qText = ns.SafeString(GetQuestText(), nil)
        if qText and qText ~= "" then record.detailText = qText end
    end
    record.objectiveText = nil

    ns.db.quests[questKey] = record

    if ns.RegisterSavedQuestInCodex then
        ns.RegisterSavedQuestInCodex(questKey, record)
    end
    ns.UnlockEntry(questKey)
end

ns.RegisterEvent("QUEST_DETAIL", CaptureQuestLore)
ns.RegisterEvent("QUEST_PROGRESS", CaptureQuestLore)
ns.RegisterEvent("QUEST_COMPLETE", CaptureQuestLore)

-- Live Quest Log Harvester: scans all quests currently accepted in the player's quest log
function ns.ScanQuestLog()
    if not ns.db then return end
    ns.db.quests = ns.db.quests or {}

    local numEntries = 0
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
    elseif GetNumQuestLogEntries then
        numEntries = GetNumQuestLogEntries() or 0
    end

    if not numEntries or numEntries <= 0 or ns.IsSecret(numEntries) then return end

    local playerZone = ns.SafeString(GetRealZoneText(), "Unknown Zone")
    local currentHeader = playerZone

    for i = 1, numEntries do
        local title, questID, isHeader = nil, nil, false

        if C_QuestLog and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(i)
            if info and not ns.IsSecret(info) then
                title = ns.SafeString(info.title, nil)
                questID = info.questID
                isHeader = info.isHeader
                if isHeader and title and title ~= "" then
                    currentHeader = title
                end
            end
        elseif GetQuestLogTitle then
            local qTitle, _, _, qIsHeader, _, _, _, qID = GetQuestLogTitle(i)
            title = ns.SafeString(qTitle, nil)
            questID = qID
            isHeader = qIsHeader
            if isHeader and title and title ~= "" then
                currentHeader = title
            end
        end

        if not isHeader and title and title ~= "" and questID and not ns.IsSecret(questID) then
            local questKey = "quest:" .. title

            -- Always select the quest log entry to extract narrative quest description
            local prevSelection = (GetQuestLogSelection and GetQuestLogSelection()) or 0
            if SelectQuestLogEntry then
                SelectQuestLogEntry(i)
            end

            local questDescription = nil
            if GetQuestLogQuestText then
                local qDesc = GetQuestLogQuestText()
                questDescription = ns.SafeString(qDesc, nil)
            end

            if (not questDescription or questDescription == "") and C_QuestLog and C_QuestLog.GetQuestDescription then
                questDescription = ns.SafeString(C_QuestLog.GetQuestDescription(questID), nil)
            end

            if prevSelection and prevSelection > 0 and SelectQuestLogEntry then
                SelectQuestLogEntry(prevSelection)
            end

            local record = ns.db.quests[questKey] or {
                title = title,
                questID = questID,
                zone = currentHeader or playerZone,
                character = ns.GetPlayerKey(),
                faction = ns.GetPlayerFaction(),
            }

            record.title = title
            record.questID = questID
            record.zone = currentHeader or record.zone or playerZone
            record.objectiveText = nil
            record.character = record.character or ns.GetPlayerKey()
            record.faction = record.faction or ns.GetPlayerFaction()

            -- Store questDescription as the pure narrative lore body
            if questDescription and questDescription ~= "" then
                record.detailText = questDescription
            end

            ns.db.quests[questKey] = record

            if ns.RegisterSavedQuestInCodex then
                ns.RegisterSavedQuestInCodex(questKey, record)
            end
            ns.UnlockEntry(questKey)
        end
    end
end

ns.RegisterEvent("QUEST_LOG_UPDATE", ns.ScanQuestLog)
ns.RegisterEvent("QUEST_ACCEPTED", ns.ScanQuestLog)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
    ns.ScanQuestLog()
    C_Timer.After(1.5, function()
        if ns.ScanQuestLog then
            ns.ScanQuestLog()
        end
    end)
end)

-- ==========================================
-- 8. RELIC & DYNAMIC ITEM REGISTRATION
-- ==========================================
function ns.RegisterSavedItemInCodex(itemKey, itemData)
    local rawStory = string.format("|cffd4a85aFlavor Text:|r\n|cffffd200\"%s\"|r", itemData.flavorText or "")
    local wovenStory, relatedKeys = ns.WeaveTextConnections(rawStory)

    local entryObj = {
        key = itemKey,
        category = "Relic",
        triggerType = "ITEM",
        triggerValue = itemData.itemID,
        title = itemData.title or ("Item #" .. tostring(itemData.itemID)),
        era = "Harvested Relic",
        summary = itemData.flavorText and ('"' .. itemData.flavorText .. '"') or "A mysterious artifact inscribed with ancient flavor text.",
        story = wovenStory,
        related = relatedKeys,
        icon = itemData.icon,
        character = itemData.character,
        faction = itemData.faction,
    }

    if not ns.LoreByKey[itemKey] then
        table.insert(ns.LoreEntries, entryObj)
    else
        for i, existing in ipairs(ns.LoreEntries) do
            if existing.key == itemKey then
                ns.LoreEntries[i] = entryObj
                break
            end
        end
    end
    ns.LoreByKey[itemKey] = entryObj
    ns.LoreByItem = ns.LoreByItem or {}
    ns.LoreByItem[itemData.itemID] = itemKey
end
