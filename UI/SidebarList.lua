-- =========================================================================
-- UI/SidebarList.lua
-- Accordion grouped sidebar with collapsible folders, zebra striping & dynamic rows.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

ns.selectedKey = nil
ns.listScrollOffset = 0
ns.filteredCount = 0
ns.filteredEntries = {}
ns.displayRows = {}
local listButtons = {}
local isUpdatingScrollBar = false

function ns.ResetListOffset()
    ns.listScrollOffset = 0
end

-- -------------------------------------------------------------------------
-- Build Sidebar List UI Elements
-- -------------------------------------------------------------------------
local main = ChronicleWeaverMainFrame
local listPanel = main and main.listPanel

if not listPanel then
    error("ChronicleWeaver: listPanel missing in MainFrame.")
end

-- Helper: Get dynamic visible row count based on listPanel height
local function GetVisibleRows()
    local panelH = listPanel:GetHeight() or 500
    return math.max(10, math.floor((panelH - 38) / 23))
end

-- -------------------------------------------------------------------------
-- Free Scrolling (Mouse-Wheel & Slider Dragging)
-- -------------------------------------------------------------------------
local function ScrollListByDelta(delta)
    local visibleRows = GetVisibleRows()
    local maxOffset = math.max(0, #ns.displayRows - visibleRows)
    if maxOffset == 0 then
        ns.listScrollOffset = 0
    else
        ns.listScrollOffset = math.max(0, math.min(maxOffset, ns.listScrollOffset - delta * 3))
    end
    if ns.RefreshSidebarRows then
        ns.RefreshSidebarRows()
    end
end

-- Enforce solid dark obsidian framing in both themes
listPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 0,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
listPanel:SetBackdropColor(0.06, 0.05, 0.05, 0.95)
listPanel:SetBackdropBorderColor(0.35, 0.28, 0.18, 0.8)

listPanel:EnableMouseWheel(true)
listPanel:SetScript("OnMouseWheel", function(_, delta)
    ScrollListByDelta(delta)
end)

-- Vertical Scrollbar Slider on Right Edge of listPanel
local listScrollBar = CreateFrame("Slider", "ChronicleWeaverListScrollBar", listPanel, "BackdropTemplate")
listScrollBar:SetPoint("TOPRIGHT", -5, -8)
listScrollBar:SetPoint("BOTTOMRIGHT", -5, 20)
listScrollBar:SetWidth(8)
listScrollBar:SetOrientation("VERTICAL")

local scrollTrack = listScrollBar:CreateTexture(nil, "BACKGROUND")
scrollTrack:SetAllPoints()
scrollTrack:SetColorTexture(0.04, 0.04, 0.05, 0.75)

local scrollThumb = listScrollBar:CreateTexture(nil, "OVERLAY")
scrollThumb:SetSize(8, 26)
scrollThumb:SetColorTexture(0.83, 0.66, 0.35, 0.90)
listScrollBar:SetThumbTexture(scrollThumb)

listScrollBar:SetMinMaxValues(0, 0)
listScrollBar:SetValueStep(1)
listScrollBar:SetObeyStepOnDrag(true)
listScrollBar:SetValue(0)
listScrollBar:EnableMouseWheel(true)
listScrollBar:SetScript("OnMouseWheel", function(_, delta)
    ScrollListByDelta(delta)
end)

listScrollBar:SetScript("OnValueChanged", function(_, value)
    if isUpdatingScrollBar then return end
    isUpdatingScrollBar = true
    local offset = math.floor(value + 0.5)
    if offset ~= ns.listScrollOffset then
        ns.listScrollOffset = offset
        if ns.RefreshSidebarRows then
            ns.RefreshSidebarRows()
        end
    end
    isUpdatingScrollBar = false
end)

-- Bottom List Item Range Indicator (e.g., "1 - 21 of 58")
local listScrollIndicator = listPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
listScrollIndicator:SetPoint("BOTTOMLEFT", 10, 5)
listScrollIndicator:SetPoint("BOTTOMRIGHT", -15, 5)
listScrollIndicator:SetJustifyH("CENTER")
listScrollIndicator:SetTextColor(0.65, 0.58, 0.48)

-- -------------------------------------------------------------------------
-- Factory: Ensure List Row Button (On-Demand Dynamic Creation)
-- -------------------------------------------------------------------------
local function EnsureListButton(index)
    if listButtons[index] then
        return listButtons[index]
    end

    local btn = CreateFrame("Button", "ChronicleWeaverListBtn" .. index, listPanel)
    btn:SetHeight(22)
    btn:SetPoint("TOPLEFT", 6, -6 - (index - 1) * 23)

    -- Row Hover Highlight
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.83, 0.66, 0.35, 0.18)

    -- Row Selection Highlight
    local sel = btn:CreateTexture(nil, "BACKGROUND")
    sel:SetAllPoints()
    sel:SetColorTexture(0.83, 0.66, 0.35, 0.30)
    sel:Hide()
    btn.sel = sel

    -- Alternating Zebra Stripe Texture
    local zebra = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    zebra:SetAllPoints()
    zebra:SetColorTexture(0.08, 0.07, 0.06, 0.40)
    zebra:Hide()
    btn.zebra = zebra

    -- Group Header Banner Fill
    local headerBg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.18, 0.14, 0.10, 0.95)
    headerBg:Hide()
    btn.headerBg = headerBg

    -- Group Header Left Gold Accent Bar
    local headerAccent = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    headerAccent:SetPoint("TOPLEFT", 0, 0)
    headerAccent:SetPoint("BOTTOMLEFT", 0, 0)
    headerAccent:SetWidth(3)
    headerAccent:SetColorTexture(0.88, 0.72, 0.35, 1.0)
    headerAccent:Hide()
    btn.headerAccent = headerAccent

    -- 14x14 Row Icon Texture with Desaturation Support
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    -- Row Text (Strict 1-Line Typography)
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    text:SetPoint("RIGHT", -4, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    if text.SetNonSpaceWrap then
        text:SetNonSpaceWrap(false)
    end
    btn.text = text

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn:SetScript("OnClick", function(self, button)
        if self.isHeader then
            if self.groupKey and ns.db then
                ns.db.collapsedGroups = ns.db.collapsedGroups or {}
                ns.db.collapsedGroups[self.groupKey] = not ns.db.collapsedGroups[self.groupKey]
                if ns.RefreshSidebarRows then
                    ns.RefreshSidebarRows()
                end
            end
        elseif self.itemKey then
            if button == "RightButton" then
                -- Toggle favorite
                if ns.db then
                    ns.db.favorites = ns.db.favorites or {}
                    ns.db.favorites[self.itemKey] = not ns.db.favorites[self.itemKey] or nil
                end
                if ns.RefreshSidebarRows then
                    ns.RefreshSidebarRows()
                end
            else
                ns.SelectEntry(self.itemKey)
            end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        if self.isHeader then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.groupTitle or "Group", 1, 0.82, 0.45)
            GameTooltip:AddLine("Click to toggle folder expansion.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        elseif self.itemKey and ns.LoreByKey and ns.LoreByKey[self.itemKey] then
            local item = ns.LoreByKey[self.itemKey]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(item.title or "Unknown", 1, 0.82, 0.45)
            if item.zone and item.zone ~= "" then
                GameTooltip:AddLine("Zone: " .. item.zone, 0.75, 0.75, 0.75)
            end
            GameTooltip:AddLine("Left-Click: Read Chronicle", 0.6, 0.8, 1.0)
            GameTooltip:AddLine("Right-Click: Toggle Favorite (*)", 0.6, 0.8, 1.0)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    listButtons[index] = btn
    return btn
end
ns.listButtons = listButtons

-- -------------------------------------------------------------------------
-- Entry Selection Handler
-- -------------------------------------------------------------------------
function ns.SelectEntry(entryKey)
    if not entryKey then return end
    ns.selectedKey = entryKey

    local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
    local switchedTab = false
    if entry and entry.category then
        local targetCat = (entry.category == "Gossip") and "NPC" or entry.category
        if ns.db and ns.db.collapsedGroups then
            local z = entry.zone
            if not z or z == "" or z == "Unknown" or z == "Azeroth" then
                z = entry.era or "General Lore"
            end
            ns.db.collapsedGroups["ZONE_" .. z:lower()] = nil
            ns.db.collapsedGroups["GROUP_FAVORITES"] = nil
        end
        if ns.activeCategory ~= targetCat then
            ns.activeCategory = targetCat
            ns.listScrollOffset = 0
            switchedTab = true
        end
    end

    if switchedTab and ns.RefreshUI then
        ns.RefreshUI()
    else
        if ns.RefreshSidebarRows then
            ns.RefreshSidebarRows()
        end
        if ns.RefreshReaderView then
            ns.RefreshReaderView()
        end
    end

    -- Ensure the selected entry is scrolled into view in the sidebar
    if ns.displayRows and #ns.displayRows > 0 then
        local visibleRows = GetVisibleRows()
        for idx, row in ipairs(ns.displayRows) do
            if not row.isHeader and row.entry and row.entry.key == entryKey then
                if idx <= ns.listScrollOffset or idx > (ns.listScrollOffset + visibleRows) then
                    local maxOffset = math.max(0, #ns.displayRows - visibleRows)
                    ns.listScrollOffset = math.max(0, math.min(maxOffset, idx - math.floor(visibleRows / 2)))
                    if ns.RefreshSidebarRows then
                        ns.RefreshSidebarRows()
                    end
                end
                break
            end
        end
    end
end

-- -------------------------------------------------------------------------
-- Filtering & Sorting Pipeline
-- -------------------------------------------------------------------------
local function MatchesFaction(entry, filterFaction)
    if not filterFaction or filterFaction == "ALL" then return true end
    local f = entry.faction
    if not f and ns.db and ns.db.discoveredMeta and ns.db.discoveredMeta[entry.key] then
        f = ns.db.discoveredMeta[entry.key].faction
    end
    if not f or f == "" or f == "Neutral" then
        return true
    end
    return f:lower() == filterFaction:lower()
end

local function MatchesCharacter(entry, charFilter)
    if not charFilter or charFilter == "ALL" then return true end
    if entry.isHarvested or entry.category == "Quest" or entry.category == "Book" or entry.category == "Gossip" then
        return ns.IsEntryForCurrentCharacter and ns.IsEntryForCurrentCharacter(entry) or false
    end
    if ns.db and ns.db.spoilerFree then
        return ns.IsEntryForCurrentCharacter and ns.IsEntryForCurrentCharacter(entry) or false
    end
    return true
end

local function FilterAndSortEntries()
    local filtered = {}
    local activeCat = ns.activeCategory or "Zone"
    if activeCat == "ALL" then
        activeCat = "Zone"
        ns.activeCategory = "Zone"
    end
    local query = ns.searchQuery or ""
    local factionFilter = (ns.db and ns.db.factionFilter) or "ALL"
    local charFilter = (ns.db and ns.db.charFilter) or "ALL"
    local isSpoilerFree = (ns.db and ns.db.spoilerFree == true)

    if ns.LoreEntries then
        for _, entry in ipairs(ns.LoreEntries) do
            if entry.category == "Dossier" and (not entry.era or entry.era == "Unknown") then
                entry.era = "Lore Dossier"
            end

            -- 1. Strict Spoiler-Safe filtering: skip undiscovered entries completely
            if not isSpoilerFree or (ns.IsEntryUnlocked and ns.IsEntryUnlocked(entry)) then
                local catMatch = (entry.category == activeCat)
                    or (activeCat == "NPC" and entry.category == "Gossip")
                local queryMatch = (query == "")
                    or (entry.title and entry.title:lower():find(query, 1, true))
                    or (entry.summary and entry.summary:lower():find(query, 1, true))
                    or (entry.zone and entry.zone:lower():find(query, 1, true))
                local factionMatch = MatchesFaction(entry, factionFilter)
                local charMatch = MatchesCharacter(entry, charFilter)

                if catMatch and queryMatch and factionMatch and charMatch then
                    table.insert(filtered, entry)
                end
            end
        end
    end

    -- Sorting: Favorites first, then alphabetical by title
    local favs = (ns.db and ns.db.favorites) or {}
    table.sort(filtered, function(a, b)
        local aFav = favs[a.key] and 1 or 0
        local bFav = favs[b.key] and 1 or 0
        if aFav ~= bFav then
            return aFav > bFav
        end
        return (a.title or a.key):lower() < (b.title or b.key):lower()
    end)

    ns.filteredEntries = filtered
    ns.filteredCount = #filtered
    return filtered
end

-- -------------------------------------------------------------------------
-- Build Display Rows (Strict Per-Tab Accordion Grouping Engine)
-- -------------------------------------------------------------------------
local function BuildDisplayRows(filtered)
    local favs = (ns.db and ns.db.favorites) or {}
    local groupMode = (ns.db and ns.db.groupMode) or "ZONE"
    local activeCat = ns.activeCategory or "Zone"
    local isCollapsed = function(key)
        return ns.db and ns.db.collapsedGroups and ns.db.collapsedGroups[key] == true
    end
    local isUnlocked = function(key)
        return ns.IsEntryUnlocked and ns.IsEntryUnlocked(key)
    end

    -- Zone and Dossier tabs (or Flat mode) render as a clean direct list without redundant 1-item folders
    if groupMode == "NONE" or activeCat == "Zone" or activeCat == "Dossier" then
        local rows = {}
        for _, entry in ipairs(filtered) do
            table.insert(rows, { isHeader = false, entry = entry })
        end
        return rows
    end

    local groups = {}
    local favEntries = {}
    local zoneMap = {}
    local zoneOrder = {}

    for _, entry in ipairs(filtered) do
        if favs[entry.key] then
            table.insert(favEntries, entry)
        else
            local z = entry.zone
            if not z or z == "" or z == "Unknown" or z == "Azeroth" then
                z = entry.era or "General Lore"
            end
            if not zoneMap[z] then
                zoneMap[z] = {}
                table.insert(zoneOrder, z)
            end
            table.insert(zoneMap[z], entry)
        end
    end

    table.sort(zoneOrder, function(a, b) return a:lower() < b:lower() end)

    if #favEntries > 0 then
        table.insert(groups, { key = "GROUP_FAVORITES", title = "* Favorites", entries = favEntries })
    end
    for _, z in ipairs(zoneOrder) do
        if zoneMap[z] and #zoneMap[z] > 0 then
            table.insert(groups, { key = "ZONE_" .. z:lower(), title = z, entries = zoneMap[z] })
        end
    end

    -- Flatten groups into displayRows
    local rows = {}
    for _, grp in ipairs(groups) do
        local unlocked = 0
        for _, e in ipairs(grp.entries) do
            if isUnlocked(e.key) then
                unlocked = unlocked + 1
            end
        end
        local collapsed = isCollapsed(grp.key)
        table.insert(rows, {
            isHeader = true,
            groupKey = grp.key,
            title = grp.title,
            unlocked = unlocked,
            total = #grp.entries,
            isCollapsed = collapsed,
        })

        if not collapsed then
            for _, e in ipairs(grp.entries) do
                table.insert(rows, {
                    isHeader = false,
                    entry = e,
                    groupKey = grp.key,
                })
            end
        end
    end

    return rows
end

-- -------------------------------------------------------------------------
-- Refresh Sidebar Rows (Dynamic Visible Rows & Flexible Width)
-- -------------------------------------------------------------------------
function ns.RefreshSidebarRows()
    if not main:IsShown() then return end

    local filtered = ns.filteredEntries or FilterAndSortEntries()
    local displayRows = BuildDisplayRows(filtered)
    ns.displayRows = displayRows

    local visibleRows = GetVisibleRows()
    local total = #displayRows
    local maxOffset = math.max(0, total - visibleRows)

    -- Guard scroll offset within valid bounds
    if ns.listScrollOffset > maxOffset then
        ns.listScrollOffset = maxOffset
    end
    if ns.listScrollOffset < 0 then
        ns.listScrollOffset = 0
    end

    -- Sync vertical scrollbar slider
    isUpdatingScrollBar = true
    listScrollBar:SetMinMaxValues(0, maxOffset)
    listScrollBar:SetValue(ns.listScrollOffset)
    if maxOffset == 0 then
        listScrollBar:Hide()
    else
        listScrollBar:Show()
    end
    isUpdatingScrollBar = false

    -- Update bottom indicator
    if total > 0 then
        listScrollIndicator:SetText(string.format("%d - %d of %d",
            ns.listScrollOffset + 1,
            math.min(total, ns.listScrollOffset + visibleRows),
            total
        ))
    else
        if ns.db and ns.db.spoilerFree then
            listScrollIndicator:SetText("No Discovered Chronicles")
        else
            listScrollIndicator:SetText("No Chronicles Found")
        end
    end

    local favs = (ns.db and ns.db.favorites) or {}
    local groupMode = (ns.db and ns.db.groupMode) or "ZONE"
    local btnWidth = math.max(220, listPanel:GetWidth() - 26)

    -- Render dynamically sized rows
    for i = 1, visibleRows do
        local btn = EnsureListButton(i)
        btn:SetWidth(btnWidth)

        local rowIndex = ns.listScrollOffset + i
        local row = displayRows[rowIndex]

        if row then
            if row.isHeader then
                -- Group Header Row Banner
                btn.isHeader = true
                btn.groupKey = row.groupKey
                btn.groupTitle = row.title
                btn.itemKey = nil

                btn.headerBg:Show()
                btn.headerAccent:Show()
                btn.zebra:Hide()
                btn.sel:Hide()
                btn.icon:Hide()

                btn.text:ClearAllPoints()
                btn.text:SetPoint("LEFT", 10, 0)
                btn.text:SetPoint("RIGHT", -6, 0)

                local glyph = row.isCollapsed and "|cffd4a85a[+]|r" or "|cffd4a85a[-]|r"
                local countStr
                if ns.db and ns.db.spoilerFree then
                    countStr = string.format("(%d)", row.unlocked)
                else
                    countStr = string.format("(%d/%d)", row.unlocked, row.total)
                end
                btn.text:SetText(string.format("%s |cffffd100%s|r |cffaa9977%s|r", glyph, row.title, countStr))
                btn:Show()
            else
                -- Child Entry Row
                local item = row.entry
                btn.isHeader = false
                btn.groupKey = nil
                btn.groupTitle = nil
                btn.itemKey = item.key

                btn.headerBg:Hide()
                btn.headerAccent:Hide()

                -- Alternating Zebra Stripe
                if (rowIndex % 2 == 0) then
                    btn.zebra:Show()
                else
                    btn.zebra:Hide()
                end

                local isSelected = (ns.selectedKey == item.key)
                local isUnlocked = ns.IsEntryUnlocked and ns.IsEntryUnlocked(item)

                -- Auto-discover Dossier entry as soon as at least 1 clue has been discovered
                if item.category == "Dossier" then
                    if not item.era or item.era == "Unknown" then
                        item.era = "Lore Dossier"
                    end
                    if not isUnlocked then
                        local clues = ns.DossierClues and ns.DossierClues[item.key]
                        if clues and #clues > 0 then
                            for _, cKey in ipairs(clues) do
                                if ns.db and ns.db.discovered and ns.db.discovered[cKey] then
                                    isUnlocked = true
                                    ns.db.discovered[item.key] = time()
                                    break
                                end
                            end
                        end
                    end
                end

                -- 1. Selection indicator
                if isSelected then
                    btn.sel:Show()
                else
                    btn.sel:Hide()
                end

                -- 2. 10px Indentation under header when grouped
                local isGroupedTab = (groupMode ~= "NONE") and (ns.activeCategory ~= "Zone") and (ns.activeCategory ~= "Dossier")
                local indentX = isGroupedTab and 14 or 4
                btn.icon:ClearAllPoints()
                btn.icon:SetPoint("LEFT", indentX, 0)
                btn.text:ClearAllPoints()
                btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 5, 0)
                btn.text:SetPoint("RIGHT", -4, 0)

                -- 3. Cropped 14x14 Icon with Desaturation when undiscovered
                local iconPath = item.icon
                    or (ns.CategoryIcons and ns.CategoryIcons[item.category])
                    or "Interface\\Icons\\INV_Misc_Book_09"
                btn.icon:SetTexture(iconPath)
                btn.icon:SetDesaturated(not isUnlocked)
                if isUnlocked then
                    btn.icon:SetVertexColor(1.0, 1.0, 1.0, 1.0)
                else
                    btn.icon:SetVertexColor(0.55, 0.55, 0.55, 0.85)
                end
                btn.icon:Show()

                -- 4. Favorite Star
                local starStr = favs[item.key] and "|cffffd100*|r " or ""

                -- 5. Title Display: Always real title, muted grey (0.52, 0.50, 0.47) when undiscovered
                local displayTitle = item.title or item.key
                local titleStr
                if isSelected then
                    titleStr = "|cffffd100" .. displayTitle .. "|r"
                elseif isUnlocked then
                    titleStr = "|cfff2eee6" .. displayTitle .. "|r"
                else
                    titleStr = "|cff858078" .. displayTitle .. "|r"
                end

                btn.text:SetText(starStr .. titleStr)
                btn:Show()
            end
        else
            btn.itemKey = nil
            btn.groupKey = nil
            btn.isHeader = false
            btn.sel:Hide()
            btn.zebra:Hide()
            btn.headerBg:Hide()
            btn.headerAccent:Hide()
            btn.text:SetText("")
            btn.icon:SetTexture(nil)
            btn:Hide()
        end
    end

    -- Hide any surplus buttons when panel height shrank
    for i = visibleRows + 1, #listButtons do
        listButtons[i]:Hide()
    end
end

-- -------------------------------------------------------------------------
-- Full UI Refresh (called on filters, searches, tabs, discovery events)
-- -------------------------------------------------------------------------
function ns.RefreshUI()
    if not main:IsShown() then return end

    -- Update header controls
    if main.spoilerBtn then
        main.spoilerBtn:SetText(ns.db.spoilerFree and "Spoilers: Hidden" or "Spoilers: Shown")
    end

    if main.statsText then
        local totalCount = ns.LoreEntries and #ns.LoreEntries or 0
        local discoveredCount = 0
        if ns.LoreEntries then
            for _, e in ipairs(ns.LoreEntries) do
                if ns.IsEntryUnlocked and ns.IsEntryUnlocked(e) then
                    discoveredCount = discoveredCount + 1
                end
            end
        end
        if ns.db and ns.db.spoilerFree then
            main.statsText:SetText(string.format("Discovered: %d", discoveredCount))
        else
            main.statsText:SetText(string.format("Discovered: %d / %d", discoveredCount, totalCount))
        end
    end

    if main.themeBtn then
        main.themeBtn:SetText((ns.db and ns.db.theme == "PARCHMENT") and "Theme: Parchment" or "Theme: Dark")
    end

    if main.groupBtn then
        local mode = (ns.db and ns.db.groupMode) or "ZONE"
        if mode ~= "NONE" then
            main.groupBtn:SetText("Group: Zone")
        else
            main.groupBtn:SetText("Group: Flat")
        end
    end

    if main.charBtn then
        local cMode = (ns.db and ns.db.charFilter) or "ALL"
        if cMode == "CURRENT" then
            main.charBtn:SetText("Scope: |cff4cd964Char|r")
        else
            main.charBtn:SetText("Scope: Account")
        end
    end

    if main.factionBtn then
        local currentFaction = ns.db.factionFilter or "ALL"
        if currentFaction == "Alliance" then
            main.factionBtn:SetText("Faction: |cff00aaffAlliance|r")
        elseif currentFaction == "Horde" then
            main.factionBtn:SetText("Faction: |cffff3b30Horde|r")
        elseif currentFaction == "Neutral" then
            main.factionBtn:SetText("Faction: |cff4cd964Neutral|r")
        else
            main.factionBtn:SetText("Faction: All")
        end
    end

    -- Update category tabs visual state (Sleek Journal Tabs)
    if main.catButtons then
        for cat, btn in pairs(main.catButtons) do
            if cat == ns.activeCategory then
                btn:SetBackdropColor(0.24, 0.18, 0.11, 1.0)
                btn:SetBackdropBorderColor(0.88, 0.72, 0.38, 1.0)
                btn.text:SetTextColor(1.0, 0.95, 0.82)
                btn.glowBar:Show()
            else
                btn:SetBackdropColor(0.10, 0.09, 0.08, 0.95)
                btn:SetBackdropBorderColor(0.35, 0.28, 0.18, 1.0)
                btn.text:SetTextColor(0.75, 0.68, 0.55)
                btn.glowBar:Hide()
            end
        end
    end

    -- Filter and sort entries
    local filtered = FilterAndSortEntries()

    -- Auto-select first item if current selection is invalid or became hidden under spoiler-safe mode
    local isSelectedVisible = false
    if ns.selectedKey then
        for _, entry in ipairs(filtered) do
            if entry.key == ns.selectedKey then
                isSelectedVisible = true
                break
            end
        end
    end

    if not isSelectedVisible then
        if filtered[1] then
            ns.selectedKey = filtered[1].key
        else
            ns.selectedKey = nil
        end
    end

    ns.RefreshSidebarRows()

    if ns.RefreshReaderView then
        ns.RefreshReaderView()
    end
end
