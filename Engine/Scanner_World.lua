-- =========================================================================
-- Engine/Scanner_World.lua
-- Zone/Subzone, Target NPC, Bag Relics, and Unit/Item Tooltip hooks.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

-- -------------------------------------------------------------------------
-- 1. Zone & Subzone Discovery Scanner
-- -------------------------------------------------------------------------
local function CheckCurrentZone()
    if not ns.LoreByZone or not ns.db then return end

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
    if not ns.LoreByNPC or not ns.db then return end

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
-- 4. Bag Scanner for Known Relics & Curios
-- -------------------------------------------------------------------------
local function ScanBagsForRelics()
    if not ns.LoreByItem or not ns.db or not C_Container or not C_Container.GetContainerNumSlots then return end

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

-- -------------------------------------------------------------------------
-- 5. Tooltip Hooks (NPC Lore & Flavor-Text Relic Harvester)
-- -------------------------------------------------------------------------
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    -- NPC / Unit Tooltip Hook
    if Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip ~= GameTooltip or not ns.LoreByNPC or not ns.db then return end

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

    -- Relic / Item Tooltip Hook (Dynamic Flavor Harvester)
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

            -- (a) Existing Curated or Previously Harvested Relic
            local entryKey = ns.LoreByItem and ns.LoreByItem[itemID]
            if entryKey then
                ns.InspectItemLore(itemID)
                local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
                if entry and entry.summary then
                    tooltip:AddLine(" ")
                    tooltip:AddLine("|cffd4a85a[ChronicleWeaver Relic]|r")
                    tooltip:AddLine(entry.summary, 0.9, 0.85, 0.7, true)
                end
                return
            end

            -- (b) Check for quoted flavor text line to harvest dynamically
            local flavor = nil
            if data and data.lines then
                for _, lineData in ipairs(data.lines) do
                    local lineText = lineData.leftText
                    if lineText and not ns.IsSecret(lineText) and type(lineText) == "string" then
                        local clean = lineText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$")
                        if clean then
                            local m = clean:match('^"([^"]+)"$') or clean:match("^'([^']+)'$")
                            if m and #m >= 16 then
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
                                    local m = clean:match('^"([^"]+)"$') or clean:match("^'([^']+)'$")
                                    if m and #m >= 16 then
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

                local itemName = nil
                if C_Item and C_Item.GetItemInfo then
                    itemName = select(1, C_Item.GetItemInfo(itemID))
                end
                itemName = ns.SafeString(itemName, nil)
                if not itemName and data and data.lines and data.lines[1] and data.lines[1].leftText then
                    itemName = ns.SafeString(data.lines[1].leftText, nil)
                end
                itemName = itemName or ("Item #" .. itemID)

                local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID))
                    or (ns.CategoryIcons and ns.CategoryIcons.Relic)
                    or "Interface\\Icons\\INV_Misc_Gem_Variety_01"

                local zone, subzone, mapID, x, y = ns.GetPlayerLocationData()

                local itemRecord = ns.db.items[itemKey] or {
                    itemID = itemID,
                    title = itemName,
                    icon = icon,
                    flavorText = flavor,
                    zone = zone,
                    subzone = subzone,
                    mapID = mapID,
                    x = x,
                    y = y,
                    character = ns.GetPlayerKey(),
                    faction = ns.GetPlayerFaction(),
                }
                itemRecord.title = itemName
                itemRecord.icon = icon
                itemRecord.flavorText = flavor
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
                    local shortFlavor = (#flavor > 35) and (flavor:sub(1, 32) .. "...") or flavor
                    ns.Print(string.format("Harvested flavor relic: |cffffd100%s|r (\"%s\")", itemName, shortFlavor))
                end

                tooltip:AddLine(" ")
                tooltip:AddLine("|cffd4a85a[ChronicleWeaver Relic]|r")
                tooltip:AddLine('"' .. flavor .. '"', 0.9, 0.85, 0.7, true)
            end
        end)
    end
end
