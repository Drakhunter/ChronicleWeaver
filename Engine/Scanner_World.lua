-- =========================================================================
-- Engine/Scanner_World.lua
-- Zone/Subzone, Target NPC, Bag Relics, and Unit/Item Tooltip hooks.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

-- -------------------------------------------------------------------------
-- 1. Zone & Subzone Discovery Scanner
-- -------------------------------------------------------------------------
local function CheckCurrentZone()
    if not ns.LoreByZone or not ns.db or ns.db.trackWorld == false then return end

    local zone, subzone = ns.GetPlayerLocationData()
    local subKey = (subzone and subzone ~= "") and ns.LoreByZone[subzone:lower()]
    local zoneKey = (zone and zone ~= "") and ns.LoreByZone[zone:lower()]

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

-- -------------------------------------------------------------------------
-- 2. Target NPC Discovery Scanner (Secret-Value Guarded)
-- -------------------------------------------------------------------------
ns.RegisterEvent("PLAYER_TARGET_CHANGED", function()
    if not ns.LoreByNPC or not ns.db or ns.db.trackWorld == false then return end

    local exists = UnitExists("target")
    if ns.IsSecret(exists) or not exists then return end

    local targetName = UnitName("target")
    if not targetName or ns.IsSecret(targetName) then return end

    local npcKey = ns.LoreByNPC[targetName:lower()]
    if npcKey then
        ns.UnlockEntry(npcKey)
    end
end)

-- -------------------------------------------------------------------------
-- 3. Asynchronous Item / Relic Lore Lookup
-- -------------------------------------------------------------------------
function ns.InspectItemLore(itemID)
    if not itemID or not ns.LoreByItem or not ns.db then return end
    local entryKey = ns.LoreByItem[itemID]
    if not entryKey then return end

    if C_Item and C_Item.GetItemInfo then
        local itemName = C_Item.GetItemInfo(itemID)
        if itemName and not ns.IsSecret(itemName) then
            ns.UnlockEntry(entryKey)
        elseif C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end
end

ns.RegisterEvent("ITEM_DATA_LOAD_RESULT", function(_, itemID, success)
    if not success or not ns.LoreByItem or not ns.db then return end
    local entryKey = ns.LoreByItem[itemID]
    if entryKey then
        ns.UnlockEntry(entryKey)
    end
end)

-- -------------------------------------------------------------------------
-- 4. Deliverable & Relic Harvesting Helpers + Bag Scanner
-- -------------------------------------------------------------------------
local function MatchQuotedFlavor(lineText)
    if not lineText or ns.IsSecret(lineText) or type(lineText) ~= "string" then
        return nil
    end
    local clean = lineText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$")
    if not clean then return nil end
    local m = clean:match('^"([^"]+)"$') or clean:match("^'([^']+)'$")
    if m and #m >= 16 then
        return m
    end
    return nil
end

local function ExtractTooltipFlavorText(tooltip, data)
    if data and data.lines then
        for _, lineData in ipairs(data.lines) do
            local m = MatchQuotedFlavor(lineData.leftText)
            if m then return m end
        end
    end

    if tooltip and tooltip.GetName then
        local tName = tooltip:GetName()
        local numLines = tooltip.NumLines and tooltip:NumLines()
        if tName and numLines and not ns.IsSecret(numLines) then
            for i = 1, numLines do
                local fs = _G[tName .. "TextLeft" .. i]
                if fs and fs.GetText then
                    local m = MatchQuotedFlavor(fs:GetText())
                    if m then return m end
                end
            end
        end
    end

    return nil
end

local function ResolveItemTitle(itemID, fallbackTitle, data)
    local itemName = nil
    if C_Item and C_Item.GetItemInfo then
        itemName = select(1, C_Item.GetItemInfo(itemID))
    end
    itemName = ns.SafeString(itemName, nil)
    if itemName == "" then itemName = nil end

    if not itemName and data and data.lines and data.lines[1] and data.lines[1].leftText then
        itemName = ns.SafeString(data.lines[1].leftText, nil)
        if itemName == "" then itemName = nil end
    end

    if not itemName and fallbackTitle and fallbackTitle ~= "" then
        itemName = fallbackTitle
    end

    return itemName or ("Item #" .. itemID)
end

local function GetKnownDeliverableTitle(itemID)
    if ns.LibraryBookIDs and ns.LibraryBookIDs[itemID] then
        return ns.LibraryBookIDs[itemID]
    end
    if ns.ClassicDeliverableItems and ns.ClassicDeliverableItems[itemID] then
        return ns.ClassicDeliverableItems[itemID].title
    end
    return nil
end

local function HarvestItemRecord(itemID, flavor, deliveryInfo, data, knownTitle)
    local itemKey = "item:" .. itemID
    ns.db.items = ns.db.items or {}
    local existing = ns.db.items[itemKey]
    local isNew = (existing == nil)

    local fallbackTitle = knownTitle or (existing and existing.title) or GetKnownDeliverableTitle(itemID)
    local itemName = ResolveItemTitle(itemID, fallbackTitle, data)

    if not deliveryInfo and ns.GetItemDeliveryInfo then
        deliveryInfo = ns.GetItemDeliveryInfo(itemID, flavor or (existing and existing.flavorText), itemName)
    end

    local defaultIcon = (deliveryInfo and deliveryInfo.isLibraryBook and ns.CategoryIcons and ns.CategoryIcons.Book)
        or (ns.CategoryIcons and ns.CategoryIcons.Relic)
        or "Interface\\Icons\\INV_Misc_Gem_Variety_01"
    local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID))
        or (existing and existing.icon)
        or defaultIcon

    local zone, subzone, mapID, x, y = ns.GetPlayerLocationData()
    local playerKey = ns.GetPlayerKey()

    local itemRecord = existing or {
        itemID = itemID,
        title = itemName,
        icon = icon,
        flavorText = flavor,
        zone = zone,
        subzone = subzone,
        mapID = mapID,
        x = x,
        y = y,
        character = playerKey,
        characters = {},
        faction = ns.GetPlayerFaction(),
    }
    itemRecord.title = itemName
    itemRecord.icon = icon
    if flavor and flavor ~= "" then
        itemRecord.flavorText = flavor
    end
    itemRecord.characters = itemRecord.characters or {}
    if itemRecord.character then itemRecord.characters[itemRecord.character] = true end
    itemRecord.characters[playerKey] = true
    if x and x > 0 then
        itemRecord.mapID = mapID
        itemRecord.x = x
        itemRecord.y = y
    end
    ns.db.items[itemKey] = itemRecord

    if ns.RegisterSavedItemInCodex then
        ns.RegisterSavedItemInCodex(itemKey, itemRecord)
    end
    ns.UnlockEntry(itemKey)

    if isNew then
        if ns.ScheduleLoreWebRebuild then
            ns.ScheduleLoreWebRebuild(0.5)
        end
        if ns.db.chatAlerts ~= false then
            if deliveryInfo and deliveryInfo.isLibraryBook then
                ns.Print(string.format("Harvested library book: |cffffd100%s|r", itemName))
            elseif flavor and flavor ~= "" then
                local shortFlavor = (#flavor > 35) and (flavor:sub(1, 32) .. "...") or flavor
                ns.Print(string.format("Harvested flavor relic: |cffffd100%s|r (\"%s\")", itemName, shortFlavor))
            else
                ns.Print(string.format("Harvested deliverable lore item: |cffffd100%s|r", itemName))
            end

            if deliveryInfo and deliveryInfo.primary and ns.db.showDeliveryHints ~= false then
                local p = deliveryInfo.primary
                local coordStr = p.coords and (" (" .. p.coords .. ")") or ""
                ns.Print(string.format("Delivery Hint: Turn in to |cffffd100%s|r (%s%s)", p.npc, p.location, coordStr))
            end
        end
    end

    return itemRecord, isNew
end

local function ScanBagsForRelics()
    if not ns.db or ns.db.trackRelics == false or not C_Container or not C_Container.GetContainerNumSlots then return end

    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots and not ns.IsSecret(numSlots) and numSlots > 0 then
            for slot = 1, numSlots do
                local itemID = C_Container.GetContainerItemID(bag, slot)
                if itemID and not ns.IsSecret(itemID) and type(itemID) == "number" then
                    if ns.LoreByItem and ns.LoreByItem[itemID] then
                        ns.InspectItemLore(itemID)
                    elseif not (ns.db.items and ns.db.items["item:" .. itemID]) then
                        local knownTitle = GetKnownDeliverableTitle(itemID)
                        local cachedName = C_Item and C_Item.GetItemInfo and ns.SafeString(select(1, C_Item.GetItemInfo(itemID)), nil)
                        if cachedName == "" then cachedName = nil end
                        local deliveryInfo = ns.GetItemDeliveryInfo and ns.GetItemDeliveryInfo(itemID, nil, cachedName or knownTitle)
                        if deliveryInfo then
                            HarvestItemRecord(itemID, nil, deliveryInfo, nil, knownTitle)
                        end
                    end
                end
            end
        end
    end
end

ns.RegisterEvent("BAG_UPDATE_DELAYED", ScanBagsForRelics)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", ScanBagsForRelics)

local function AddItemLoreTooltipBlock(tooltip, bodyText, deliveryInfo)
    if not tooltip or not tooltip.AddLine then return end
    tooltip:AddLine(" ")
    local header = (deliveryInfo and deliveryInfo.isLibraryBook)
        and "|cffd4a85a[ChronicleWeaver Library Book]|r"
        or "|cffd4a85a[ChronicleWeaver Relic]|r"
    tooltip:AddLine(header)
    if bodyText and bodyText ~= "" then
        tooltip:AddLine(bodyText, 0.9, 0.85, 0.7, true)
    end
    if deliveryInfo and ns.AddDeliveryHintToTooltip then
        ns.AddDeliveryHintToTooltip(tooltip, deliveryInfo)
    end
end

-- -------------------------------------------------------------------------
-- 5. Tooltip Hooks (NPC Lore & Flavor-Text / Deliverable Harvester)
-- -------------------------------------------------------------------------
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    -- NPC / Unit Tooltip Hook
    if Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip ~= GameTooltip or not ns.LoreByNPC or not ns.db or ns.db.showTooltips == false then return end

            local name = tooltip.GetUnit and select(1, tooltip:GetUnit())
            if not name or ns.IsSecret(name) then return end

            local entryKey = ns.LoreByNPC[name:lower()]
            if not entryKey then return end

            local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
            if not entry then return end
            local isDiscovered = ns.db.discovered and (ns.db.discovered[entryKey] ~= nil)

            tooltip:AddLine(" ")
            tooltip:AddLine("|cffd4a85a[ChronicleWeaver Lore]|r")
            if isDiscovered or not ns.db.spoilerFree then
                tooltip:AddLine(entry.summary or entry.title, 0.9, 0.85, 0.7, true)
            else
                tooltip:AddLine("Target this character to unlock their chronicle entry.", 0.6, 0.6, 0.6, true)
            end
        end)
    end

    -- Relic / Item Tooltip Hook (Dynamic Flavor & Deliverable Book Harvester)
    if Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if not tooltip or not ns.db then return end
            if ns.db.showTooltips == false and ns.db.trackRelics == false then return end

            local itemID = data and data.id
            if not itemID and tooltip.GetItem then
                local _, itemLink = tooltip:GetItem()
                if itemLink and not ns.IsSecret(itemLink) and C_Item and C_Item.GetItemInfoInstant then
                    itemID = C_Item.GetItemInfoInstant(itemLink)
                end
            end

            if not itemID or ns.IsSecret(itemID) or type(itemID) ~= "number" then return end

            -- (a) Existing Curated or Previously Registered Relic
            local entryKey = ns.LoreByItem and ns.LoreByItem[itemID]
            if entryKey then
                if ns.db.trackRelics ~= false then
                    ns.InspectItemLore(itemID)
                end
                if ns.db.showTooltips ~= false then
                    local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
                    local deliveryInfo = ns.GetItemDeliveryInfo and ns.GetItemDeliveryInfo(itemID, entry and entry.summary, entry and entry.title)
                    if (entry and entry.summary and entry.summary ~= "") or deliveryInfo then
                        AddItemLoreTooltipBlock(tooltip, entry and entry.summary, deliveryInfo)
                    end
                end
                return
            end

            -- (b) Check for quoted flavor text or deliverable lore item to harvest & annotate
            local flavor = ExtractTooltipFlavorText(tooltip, data)
            local knownTitle = GetKnownDeliverableTitle(itemID)
            local resolvedTitle = ResolveItemTitle(itemID, knownTitle, data)
            local deliveryInfo = ns.GetItemDeliveryInfo and ns.GetItemDeliveryInfo(itemID, flavor, resolvedTitle)

            if flavor or deliveryInfo then
                if ns.db.trackRelics ~= false then
                    HarvestItemRecord(itemID, flavor, deliveryInfo, data, knownTitle)
                end
                if ns.db.showTooltips ~= false then
                    local bodyText = flavor and ('"' .. flavor .. '"') or nil
                    AddItemLoreTooltipBlock(tooltip, bodyText, deliveryInfo)
                end
            end
        end)
    end
end

-- -------------------------------------------------------------------------
-- 6. Proximity "Archivist's Whisper" Radar, WorldMap Bar & Addon Sync
-- -------------------------------------------------------------------------
local whisperedSession = {}

local function CheckProximityRadar()
    if not ns.db or ns.db.proximityRadar == false then return end
    if InCombatLockdown and InCombatLockdown() then return end

    local zone, _, mapID, px, py = ns.GetPlayerLocationData()
    if not mapID or not px or not py or px <= 0 or py <= 0 then return end

    local thresholdSq = 0.065 * 0.065

    -- 1. Check uncollected Library Books on the current map
    if ns.LibraryBookCatalog and ns.GetBagItemIDSet and ns.GetLibraryBookStatus then
        local bagSet = ns.GetBagItemIDSet()
        for _, book in ipairs(ns.LibraryBookCatalog) do
            if book.mapID == mapID and book.x and book.y and ns.IsBookEligibleForPlayer(book) then
                local status = ns.GetLibraryBookStatus(book.itemID, bagSet)
                local wKey = "book:" .. book.itemID
                if status == "MISSING" and not whisperedSession[wKey] then
                    local dx = book.x - px
                    local dy = book.y - py
                    if ((dx * dx) + (dy * dy)) <= thresholdSq then
                        whisperedSession[wKey] = true
                        local locLabel = book.subzone or zone
                        local titleLabel = (ns.db.spoilerFree == false) and book.title or "Nearby Library Book"
                        if ns.db.chatAlerts ~= false then
                            ns.Print(string.format("Your Archivist's compass hums -- an unrecorded Library Book lies nearby in |cffffd100%s|r!", locLabel))
                        end
                        if ns.ShowCompassWhisperToast then
                            ns.ShowCompassWhisperToast(titleLabel, locLabel, book.mapID, book.x, book.y)
                        end
                        return
                    end
                end
            end
        end
    end

    -- 2. Check undiscovered coordinate-tagged Lore Entries on the current map
    if ns.LoreEntries then
        for _, entry in ipairs(ns.LoreEntries) do
            if entry.mapID == mapID and entry.x and entry.x > 0 and entry.category ~= "Zone" then
                local isUnlocked = ns.IsEntryUnlocked and ns.IsEntryUnlocked(entry)
                if not isUnlocked and not whisperedSession[entry.key] then
                    local dx = entry.x - px
                    local dy = entry.y - py
                    if ((dx * dx) + (dy * dy)) <= thresholdSq then
                        whisperedSession[entry.key] = true
                        local displayLabel = (ns.db.spoilerFree == false)
                            and (entry.title or entry.key)
                            or ("Unrecorded " .. (entry.category or "Chronicle"))
                        local locLabel = entry.zone or zone
                        if ns.db.chatAlerts ~= false then
                            ns.Print(string.format("Your Archivist's compass hums -- %s lies nearby in |cffffd100%s|r.", displayLabel, locLabel))
                        end
                        if ns.ShowCompassWhisperToast then
                            ns.ShowCompassWhisperToast(displayLabel, locLabel, entry.mapID, entry.x, entry.y)
                        end
                        return
                    end
                end
            end
        end
    end
end

local radarTickerStarted = false
local function ScheduleRadarTicker()
    if radarTickerStarted or not C_Timer or not C_Timer.After then return end
    radarTickerStarted = true
    local function Tick()
        CheckProximityRadar()
        C_Timer.After(15, Tick)
    end
    C_Timer.After(8, Tick)
end

ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", CheckProximityRadar)
ns.RegisterEvent("ZONE_CHANGED", CheckProximityRadar)
ns.RegisterEvent("ZONE_CHANGED_INDOORS", CheckProximityRadar)

-- World Map Cartography Overlay Bar
local worldMapBar = nil
local lastWorldMapID = nil

local function UpdateWorldMapOverlay()
    if not WorldMapFrame then return end
    if not ns.db or ns.db.showMapOverlay == false then
        if worldMapBar then worldMapBar:Hide() end
        return
    end

    if not worldMapBar then
        local bar = CreateFrame("Frame", nil, WorldMapFrame, "BackdropTemplate")
        bar:SetSize(430, 26)
        bar:SetPoint("BOTTOM", WorldMapFrame, "BOTTOM", 0, 10)
        bar:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 5) + 25)
        bar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        bar:SetBackdropColor(0.07, 0.06, 0.05, 0.94)
        bar:SetBackdropBorderColor(0.70, 0.55, 0.22, 0.95)

        local label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", 10, 0)
        label:SetPoint("RIGHT", -114, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        bar.label = label

        local pinNearestBtn = CreateFrame("Button", nil, bar, "BackdropTemplate")
        pinNearestBtn:SetSize(102, 20)
        pinNearestBtn:SetPoint("RIGHT", -6, 0)
        pinNearestBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        pinNearestBtn:SetBackdropColor(0.18, 0.13, 0.09, 0.98)
        pinNearestBtn:SetBackdropBorderColor(0.75, 0.60, 0.28, 1.0)
        local hl = pinNearestBtn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(0.85, 0.68, 0.35, 0.20)
        local btnFS = pinNearestBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btnFS:SetPoint("CENTER", 0, 0)
        btnFS:SetText("|cffffd100Pin Missing|r")
        pinNearestBtn:SetScript("OnClick", function()
            local mapID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or nil
            local mapInfo = mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
            local mapName = mapInfo and mapInfo.name or nil
            if ns.PinNearestMissingBook then
                ns.PinNearestMissingBook(mapID, mapName)
            end
            UpdateWorldMapOverlay()
        end)
        bar.pinBtn = pinNearestBtn

        local elapsedAcc = 0
        bar:SetScript("OnUpdate", function(_, elapsed)
            elapsedAcc = elapsedAcc + elapsed
            if elapsedAcc < 0.35 then return end
            elapsedAcc = 0
            local curID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or nil
            if curID ~= lastWorldMapID then
                UpdateWorldMapOverlay()
            end
        end)

        worldMapBar = bar
    end

    local mapID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or nil
    lastWorldMapID = mapID
    local mapInfo = mapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local mapName = (mapInfo and mapInfo.name) or "Azeroth"

    local loreFound, loreTotal = 0, 0
    if mapID and ns.LoreEntries then
        local lowerName = mapName:lower()
        for _, e in ipairs(ns.LoreEntries) do
            if e.category ~= "Dossier" and ((e.mapID and e.mapID == mapID) or (e.zone and e.zone:lower() == lowerName)) then
                loreTotal = loreTotal + 1
                if ns.IsEntryUnlocked and ns.IsEntryUnlocked(e) then
                    loreFound = loreFound + 1
                end
            end
        end
    end

    local booksFound, _, booksTotal = 0, 0, 0
    if mapID and ns.GetLibraryProgressStats then
        booksFound, _, booksTotal = ns.GetLibraryProgressStats(mapID)
    end

    local parts = { string.format("|cffd4a85aCW:|r %s", mapName) }
    if loreTotal > 0 then
        table.insert(parts, string.format("Lore %d/%d", loreFound, loreTotal))
    end
    if booksTotal > 0 then
        table.insert(parts, string.format("Books %d/%d", booksFound, booksTotal))
    end
    worldMapBar.label:SetText(table.concat(parts, "  |  "))
    worldMapBar:Show()
end

ns.UpdateWorldMapOverlay = UpdateWorldMapOverlay

if WorldMapFrame then
    WorldMapFrame:HookScript("OnShow", UpdateWorldMapOverlay)
end

-- Addon Comms Prefix Registration & Receiver
local commsRegistered = false
ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
    ScheduleRadarTicker()
    if not commsRegistered and C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix("CW_LORE")
        commsRegistered = true
    end
end)

ns.RegisterEvent("CHAT_MSG_ADDON", function(_, prefix, message, channel, sender)
    if prefix ~= "CW_LORE" or not ns.db or ns.db.addonSync == false then return end
    if ns.IsSecret(message) or ns.IsSecret(sender) or type(message) ~= "string" then return end

    local senderName = tostring(sender or "Peer"):gsub("%-[^|]+$", "")
    local playerShort = ns.SafeString(UnitName("player"), "")
    if senderName == playerShort then return end

    local cmd, key, title, category, zone = message:match("^([^|]+)|([^|]+)|([^|]+)|([^|]*)|?(.*)$")
    if cmd == "SHARE" and key and title then
        local known = ns.LoreByKey and ns.LoreByKey[key]
        local suffix = known and " (In your Codex -- /cw to read)" or ""
        ns.Print(string.format("[%s Sync] |cff58a6ff%s|r shared [%s] |cffffd100%s|r (%s)%s",
            channel or "Peer", senderName, category ~= "" and category or "Lore", title, zone ~= "" and zone or "Azeroth", suffix))
    end
end)
