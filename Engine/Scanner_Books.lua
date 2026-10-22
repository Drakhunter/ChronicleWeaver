-- =========================================================================
-- Engine/Scanner_Books.lua
-- Multi-page book & plaque harvester with live ItemTextFrame HUD badge.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

-- -------------------------------------------------------------------------
-- ItemTextFrame HUD Status Badge
-- -------------------------------------------------------------------------
local function EnsureBookBadge()
    if ChronicleWeaverBookBadge or not ItemTextFrame then
        return ChronicleWeaverBookBadge
    end

    local badge = CreateFrame("Button", "ChronicleWeaverBookBadge", ItemTextFrame, "BackdropTemplate")
    badge:SetSize(280, 24)
    badge:SetPoint("TOP", ItemTextFrame, "TOP", 0, -38)
    badge:SetFrameLevel(ItemTextFrame:GetFrameLevel() + 10)

    badge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    badge:SetBackdropColor(0.08, 0.09, 0.12, 0.94)
    badge:SetBackdropBorderColor(0.75, 0.58, 0.18, 1.0)

    local text = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", badge, "CENTER", 0, 0)
    text:SetText("|cff4cd964[OK] ChronicleWeaver: Archived|r")
    badge.text = text

    badge:SetScript("OnClick", function(self)
        if self.currentBookKey then
            if ns.SelectEntry then
                ns.SelectEntry(self.currentBookKey)
            end
            if ns.ToggleMainFrame then
                ns.ToggleMainFrame()
            end
        end
    end)

    badge:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("ChronicleWeaver Book Harvester", 1, 0.82, 0.45)
        GameTooltip:AddLine("This lore text has been permanently archived in your personal Codex.", 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine("Click to view in the Codex Reader.", 0.6, 0.8, 1.0)
        GameTooltip:Show()
    end)

    badge:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ItemTextFrame:HookScript("OnHide", function()
        if ChronicleWeaverBookBadge then
            ChronicleWeaverBookBadge:Hide()
        end
    end)

    return badge
end

-- -------------------------------------------------------------------------
-- Capture & Archive In-Game Book Page
-- -------------------------------------------------------------------------
local function CaptureItemText()
    if not ns.db then return end
    ns.db.books = ns.db.books or {}

    -- 1. Resolve Document Title with fallback chain
    local rawTitle = ItemTextGetItem and ItemTextGetItem()
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
        if GameTooltipTextLeft1 and GameTooltipTextLeft1.GetText then
            rawTitle = GameTooltipTextLeft1:GetText()
        end
    end

    local title = ns.SafeString(rawTitle, nil)
    if not title or title == "" then return end

    -- 2. Resolve Page Body
    local rawPageText = ItemTextGetText and ItemTextGetText()
    if (not rawPageText or rawPageText == "" or ns.IsSecret(rawPageText)) and ItemTextPageText and ItemTextPageText.GetText then
        rawPageText = ItemTextPageText:GetText()
    end
    local pageText = ns.SafeString(rawPageText, nil)

    if not pageText or pageText == "" then
        -- Retry asynchronously once if frame was just rendered
        if ItemTextFrame and ItemTextFrame:IsShown() and not ns._retryingItemText then
            ns._retryingItemText = true
            if C_Timer and C_Timer.After then
                C_Timer.After(0.15, function()
                    ns._retryingItemText = false
                    CaptureItemText()
                end)
            end
        end
        return
    end

    -- 3. Resolve Page Number
    local pageNum = (ItemTextGetPage and ItemTextGetPage()) or 1
    if ns.IsSecret(pageNum) or type(pageNum) ~= "number" or pageNum < 1 then
        pageNum = 1
    end

    local bookKey = "book:" .. title
    local zone, subzone, mapID, x, y = ns.GetPlayerLocationData()

    -- 4. Store in SavedVariables without overwriting other pages
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
    record.pages = record.pages or {}

    local isNewPage = not record.pages[pageNum]
    if isNewPage then
        record.pageCount = (record.pageCount or 0) + 1
    end
    record.pages[pageNum] = pageText
    record.maxPage = math.max(record.maxPage or 1, pageNum)

    if (not record.x or record.x == 0) and x and x > 0 then
        record.mapID = mapID
        record.x = x
        record.y = y
    end

    ns.db.books[bookKey] = record

    -- 5. Upsert into runtime Codex index
    if ns.RegisterSavedBookInCodex then
        ns.RegisterSavedBookInCodex(bookKey, record)
    end
    ns.UnlockEntry(bookKey)

    -- 6. Update ItemTextFrame HUD Badge
    local badge = EnsureBookBadge()
    if badge then
        badge.currentBookKey = bookKey
        local totalPages = record.pageCount or record.maxPage or 1
        badge.text:SetText(string.format("|cff4cd964[OK] ChronicleWeaver: Page %d Archived (%d Page%s Total)|r",
            pageNum,
            totalPages,
            totalPages == 1 and "" or "s"
        ))
        badge:Show()
    end

    if isNewPage then
        ns.Print(string.format("Archived page %d of book |cffffd100%s|r!", pageNum, title))
    end
end

ns.RegisterEvent("ITEM_TEXT_READY", CaptureItemText)
ns.RegisterEvent("ITEM_TEXT_BEGIN", CaptureItemText)
ns.RegisterEvent("ITEM_TEXT_TRANSLATION", CaptureItemText)

-- -------------------------------------------------------------------------
-- Gossip Plaque / Inscription Harvester (for objects opening GossipFrame)
-- -------------------------------------------------------------------------
local function CheckGossipForPlaque()
    if not ns.db or not ns.db.books then return end

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
    if not text or text == "" or #text < 20 then return end

    local titleLower = title:lower()
    local isLore = titleLower:find("book")
        or titleLower:find("tome")
        or titleLower:find("scroll")
        or titleLower:find("plaque")
        or titleLower:find("tablet")
        or titleLower:find("monument")
        or titleLower:find("inscription")
        or titleLower:find("diary")
        or titleLower:find("journal")
        or titleLower:find("letter")
        or titleLower:find("chronicle")
        or titleLower:find("history")

    if isLore then
        local bookKey = "book:" .. title
        local zone, subzone, mapID, x, y = ns.GetPlayerLocationData()

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
        record.pages = record.pages or {}

        local isNew = not record.pages[1]
        record.pages[1] = text
        record.pageCount = math.max(record.pageCount or 0, 1)
        record.maxPage = math.max(record.maxPage or 1, 1)
        ns.db.books[bookKey] = record

        if ns.RegisterSavedBookInCodex then
            ns.RegisterSavedBookInCodex(bookKey, record)
        end
        ns.UnlockEntry(bookKey)

        if isNew then
            ns.Print(string.format("Archived plaque inscription: |cffffd100%s|r!", title))
        end
    end
end

ns.RegisterEvent("GOSSIP_SHOW", CheckGossipForPlaque)
