-- =========================================================================
-- UI/DossierView.lua
-- Grand Archivist Case File, Investigation Progress Bar, Synthesis Card
-- & Responsive Evidence Board for Lore Dossiers.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

local clueButtons = {}

-- -------------------------------------------------------------------------
-- Factory: Evidence Card Button (with Mouse-Wheel Forwarding)
-- -------------------------------------------------------------------------
local function EnsureClueButton(parentFrame, index)
    if clueButtons[index] then
        clueButtons[index]:SetParent(parentFrame)
        return clueButtons[index]
    end

    local btn = CreateFrame("Button", "ChronicleWeaverClueBtn" .. index, parentFrame, "BackdropTemplate")
    btn:SetHeight(40)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    -- Mouse-wheel forwarding so scrolling over evidence cards scrolls the story
    btn:EnableMouseWheel(true)
    btn:SetScript("OnMouseWheel", function(_, delta)
        if ns.ScrollStoryByDelta then
            ns.ScrollStoryByDelta(delta)
        end
    end)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.85, 0.70, 0.35, 0.16)

    -- 28x28 Icon on left of card
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", 6, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    -- Thin gold border frame around the 28x28 icon
    local iconBorder = btn:CreateTexture(nil, "OVERLAY")
    iconBorder:SetSize(32, 32)
    iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
    iconBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    iconBorder:SetVertexColor(0.70, 0.55, 0.25, 0.85)
    btn.iconBorder = iconBorder

    -- Right-aligned interactive arrow indicator (">")
    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetText(">")
    arrow:SetTextColor(0.58, 0.45, 0.28)
    btn.arrow = arrow

    -- Title line (Strict 1-line truncation, anchored before arrow)
    local title = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    title:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    if title.SetMaxLines then title:SetMaxLines(1) end
    btn.title = title

    -- Subtext / provenance
    local meta = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    meta:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
    meta:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    meta:SetJustifyH("LEFT")
    meta:SetWordWrap(false)
    if meta.SetMaxLines then meta:SetMaxLines(1) end
    btn.meta = meta

    btn:SetScript("OnClick", function(self)
        if self.isRedacted then
            return
        end
        if self.clueKey and ns.SelectEntry then
            ns.SelectEntry(self.clueKey)
        end
    end)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1.0, 0.85, 0.25, 1.0)
        if self.arrow and not self.isRedacted then
            self.arrow:SetTextColor(1.0, 0.85, 0.30)
        end

        if self.isRedacted then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Undiscovered Field Evidence", 0.85, 0.72, 0.45)
            GameTooltip:AddLine("Explore " .. (self.clueZone or "Azeroth") .. " to uncover this clue.", 0.85, 0.85, 0.85, true)
            GameTooltip:Show()
        elseif self.clueKey and ns.LoreByKey and ns.LoreByKey[self.clueKey] then
            local e = ns.LoreByKey[self.clueKey]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(e.title or "Unknown Clue", 1, 0.82, 0.45)
            if e.summary and e.summary ~= "" then
                GameTooltip:AddLine(e.summary, 0.9, 0.9, 0.9, true)
            end
            GameTooltip:AddLine("Click to open this chronicle in its category tab.", 0.6, 0.8, 1.0)
            GameTooltip:Show()
        end
    end)

    btn:SetScript("OnLeave", function(self)
        local isDark = (ns.db and ns.db.theme == "DARK")
        if self.isRedacted then
            if isDark then
                self:SetBackdropBorderColor(0.35, 0.28, 0.18, 0.60)
            else
                self:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.60)
            end
        else
            if isDark then
                self:SetBackdropBorderColor(0.55, 0.42, 0.22, 0.85)
            else
                self:SetBackdropBorderColor(0.62, 0.48, 0.28, 0.90)
            end
        end
        if self.arrow then
            self.arrow:SetTextColor(0.58, 0.45, 0.28)
        end
        GameTooltip:Hide()
    end)

    clueButtons[index] = btn
    return btn
end

-- -------------------------------------------------------------------------
-- Factory: Ensure Case Header & Investigation Progress Box
-- -------------------------------------------------------------------------
local function EnsureCaseHeaderBox(parentFrame)
    if parentFrame.caseHeaderBox then
        return parentFrame.caseHeaderBox
    end

    local box = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    box:SetHeight(48)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", function(_, delta)
        if ns.ScrollStoryByDelta then ns.ScrollStoryByDelta(delta) end
    end)

    local caseMeta = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    caseMeta:SetPoint("TOPLEFT", 10, -7)
    caseMeta:SetPoint("TOPRIGHT", -10, -7)
    caseMeta:SetJustifyH("LEFT")
    caseMeta:SetWordWrap(false)
    box.caseMeta = caseMeta

    local progressLabel = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progressLabel:SetPoint("BOTTOMLEFT", 10, 9)
    progressLabel:SetJustifyH("LEFT")
    box.progressLabel = progressLabel

    local barBg = CreateFrame("Frame", nil, box, "BackdropTemplate")
    barBg:SetHeight(10)
    barBg:SetPoint("LEFT", progressLabel, "RIGHT", 10, 0)
    barBg:SetPoint("RIGHT", box, "RIGHT", -10, 0)
    barBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    barBg:SetBackdropColor(0.05, 0.04, 0.04, 0.85)
    barBg:SetBackdropBorderColor(0.45, 0.36, 0.22, 0.85)
    box.barBg = barBg

    local barFill = barBg:CreateTexture(nil, "ARTWORK")
    barFill:SetPoint("TOPLEFT", 1, -1)
    barFill:SetPoint("BOTTOMLEFT", 1, 1)
    barFill:SetWidth(1)
    barFill:SetColorTexture(0.85, 0.68, 0.28, 0.95)
    box.barFill = barFill

    parentFrame.caseHeaderBox = box
    return box
end

-- -------------------------------------------------------------------------
-- Factory: Ensure Archivist's Synthesis & Field Directives Card
-- -------------------------------------------------------------------------
local function EnsureSynthesisBox(parentFrame)
    if parentFrame.synthesisBox then
        return parentFrame.synthesisBox
    end

    local box = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", function(_, delta)
        if ns.ScrollStoryByDelta then ns.ScrollStoryByDelta(delta) end
    end)

    -- Left gold/crimson vertical accent bar
    local accent = box:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("TOPLEFT", 2, -2)
    accent:SetPoint("BOTTOMLEFT", 2, 2)
    accent:SetWidth(3)
    accent:SetColorTexture(0.88, 0.72, 0.32, 1.0)
    box.accent = accent

    local header = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 12, -8)
    header:SetPoint("TOPRIGHT", -10, -8)
    header:SetJustifyH("LEFT")
    box.header = header

    local body = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    body:SetPoint("RIGHT", box, "RIGHT", -12, 0)
    body:SetJustifyH("LEFT")
    body:SetSpacing(3)
    box.body = body

    local leads = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leads:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -8)
    leads:SetPoint("RIGHT", box, "RIGHT", -12, 0)
    leads:SetJustifyH("LEFT")
    leads:SetSpacing(2)
    box.leads = leads

    parentFrame.synthesisBox = box
    return box
end

-- -------------------------------------------------------------------------
-- Render Dossier Evidence Board Content (Responsive Fluid Grid in ScrollChild)
-- -------------------------------------------------------------------------
function ns.RenderDossierView(parentFrame, dossierEntry, entryStoryFS)
    if not parentFrame or not dossierEntry then return 0 end

    local isDark = (ns.db and ns.db.theme == "DARK")
    local isSpoilerFree = (ns.db and ns.db.spoilerFree == true)
    local availWidth = math.max(450, (parentFrame:GetWidth() or 500) - 16)

    -- Query matched clues from WeaveEngine
    local allClues = (ns.GetDossierClues and ns.GetDossierClues(dossierEntry.key)) or {}

    -- Auto-discover Dossier if at least 1 clue has been discovered
    if ns.db and ns.db.discovered and not ns.db.discovered[dossierEntry.key] then
        for _, cKey in ipairs(allClues) do
            if ns.db.discovered[cKey] then
                ns.db.discovered[dossierEntry.key] = time()
                break
            end
        end
    end

    -- Count unlockedClues vs totalClues
    local unlockedCluesCount = 0
    for _, cKey in ipairs(allClues) do
        local cEntry = ns.LoreByKey and ns.LoreByKey[cKey]
        if cEntry and ns.IsEntryUnlocked and ns.IsEntryUnlocked(cEntry) then
            unlockedCluesCount = unlockedCluesCount + 1
        end
    end

    local totalCluesCount = #allClues
    local pct = (totalCluesCount > 0) and math.floor((unlockedCluesCount / totalCluesCount) * 100 + 0.5) or 100

    -- 1. Case Classification & Investigation Progress Banner
    local caseBox = EnsureCaseHeaderBox(parentFrame)
    caseBox:ClearAllPoints()
    caseBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    caseBox:SetWidth(availWidth)

    local caseId = dossierEntry.caseId or "ARCH-00"
    local classification = dossierEntry.classification or "Historical Investigation"
    local archivist = dossierEntry.archivist or "Grand Archivist Council"

    if isDark then
        caseBox:SetBackdropColor(0.10, 0.09, 0.08, 0.95)
        caseBox:SetBackdropBorderColor(0.65, 0.52, 0.25, 0.90)
        caseBox.caseMeta:SetText(string.format("|cffffd100[%s]|r  |cffd4a85a%s|r  |cff888888•  Filed by: %s|r", caseId, classification, archivist))
        caseBox.progressLabel:SetText(string.format("|cffd4a85aInvestigation Progress:|r %d / %d Clues (%d%%)", unlockedCluesCount, totalCluesCount, pct))
    else
        caseBox:SetBackdropColor(0.84, 0.77, 0.63, 0.95)
        caseBox:SetBackdropBorderColor(0.58, 0.44, 0.24, 0.95)
        caseBox.caseMeta:SetText(string.format("|cff7a1c14[%s]|r  |cff3d220a%s|r  |cff5c4938•  Filed by: %s|r", caseId, classification, archivist))
        caseBox.progressLabel:SetText(string.format("|cff7a1c14Investigation Progress:|r |cff2b1808%d / %d Clues (%d%%)|r", unlockedCluesCount, totalCluesCount, pct))
    end

    local barTotalW = math.max(80, availWidth - (caseBox.progressLabel:GetStringWidth() or 210) - 34)
    local fillRatio = (totalCluesCount > 0) and (unlockedCluesCount / totalCluesCount) or 1
    if fillRatio <= 0 then
        caseBox.barFill:Hide()
    else
        caseBox.barFill:SetWidth(math.max(4, math.floor((barTotalW - 2) * fillRatio)))
        if fillRatio >= 1 then
            caseBox.barFill:SetColorTexture(0.30, 0.78, 0.38, 0.95)
        else
            caseBox.barFill:SetColorTexture(0.85, 0.68, 0.28, 0.95)
        end
        caseBox.barFill:Show()
    end
    caseBox:Show()

    -- 2. Historical Briefing Story (with WeaveEngine entity highlighting)
    entryStoryFS:ClearAllPoints()
    entryStoryFS:SetPoint("TOPLEFT", caseBox, "BOTTOMLEFT", 0, -12)
    entryStoryFS:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -4, 0)

    local storyText = dossierEntry.story or dossierEntry.summary or ""
    if ns.WeaveTextConnections then
        storyText = select(1, ns.WeaveTextConnections(storyText))
    end
    if not isDark and ns.HighlightForParchment then
        storyText = ns.HighlightForParchment(storyText)
    end
    entryStoryFS:SetText(storyText)
    local storyHeight = entryStoryFS:GetStringHeight() or 60

    local currentOffsetY = 48 + 12 + storyHeight + 14

    -- 3. Archivist's Synthesis & Field Directives Card
    local synBox = EnsureSynthesisBox(parentFrame)
    if dossierEntry.synthesis or dossierEntry.leads then
        synBox:ClearAllPoints()
        synBox:SetPoint("TOPLEFT", entryStoryFS, "BOTTOMLEFT", 0, -14)
        synBox:SetWidth(availWidth)

        local reqClues = math.min(2, totalCluesCount)
        local isSynthesisUnlocked = (not isSpoilerFree) or (unlockedCluesCount >= reqClues)

        if isDark then
            synBox:SetBackdropColor(0.11, 0.09, 0.12, 0.95)
            synBox:SetBackdropBorderColor(0.75, 0.58, 0.25, 0.95)
            synBox.accent:SetColorTexture(0.92, 0.75, 0.32, 1.0)
            synBox.header:SetText(isSynthesisUnlocked
                and "|cffffd100[Archivist's Synthesis & Field Deduction — Unsealed]|r"
                or string.format("|cffd4a85a[Archivist's Synthesis — Sealed (%d / %d Clues Required)]|r", unlockedCluesCount, reqClues))
            synBox.body:SetTextColor(0.92, 0.88, 0.80)
            synBox.body:SetShadowColor(0, 0, 0, 1)
            synBox.body:SetShadowOffset(1, -1)
            synBox.leads:SetTextColor(0.75, 0.82, 0.92)
        else
            synBox:SetBackdropColor(0.85, 0.78, 0.64, 0.98)
            synBox:SetBackdropBorderColor(0.60, 0.42, 0.20, 1.0)
            synBox.accent:SetColorTexture(0.55, 0.16, 0.10, 1.0)
            synBox.header:SetText(isSynthesisUnlocked
                and "|cff7a1c14[Archivist's Synthesis & Field Deduction — Unsealed]|r"
                or string.format("|cff7a1c14[Archivist's Synthesis — Sealed (%d / %d Clues Required)]|r", unlockedCluesCount, reqClues))
            synBox.body:SetTextColor(0.16, 0.10, 0.05)
            synBox.body:SetShadowColor(0, 0, 0, 0)
            synBox.body:SetShadowOffset(0, 0)
            synBox.leads:SetTextColor(0.32, 0.22, 0.12)
        end

        if isSynthesisUnlocked then
            local synText = dossierEntry.synthesis or ""
            if ns.WeaveTextConnections then
                synText = select(1, ns.WeaveTextConnections(synText))
            end
            if not isDark and ns.HighlightForParchment then
                synText = ns.HighlightForParchment(synText)
            end
            synBox.body:SetText(synText)
        else
            synBox.body:SetText("The overarching deduction connecting these events remains sealed under Spoiler-Safe protection. Uncover at least " .. reqClues .. " field clues in Azeroth (or toggle Spoilers: Shown) to synthesize the hidden truth.")
        end

        if dossierEntry.leads and dossierEntry.leads ~= "" then
            local leadPrefix = isDark and "|cffd4a85aField Directives:|r " or "|cff7a1c14Field Directives:|r "
            synBox.leads:SetText(leadPrefix .. dossierEntry.leads)
            synBox.leads:Show()
        else
            synBox.leads:SetText("")
            synBox.leads:Hide()
        end

        local bodyH = synBox.body:GetStringHeight() or 36
        local leadsH = (dossierEntry.leads and dossierEntry.leads ~= "") and ((synBox.leads:GetStringHeight() or 18) + 8) or 0
        local synHeight = 28 + bodyH + leadsH + 12
        synBox:SetHeight(synHeight)
        synBox:Show()

        currentOffsetY = currentOffsetY + synHeight + 16
    else
        synBox:Hide()
    end

    -- 4. Clues Header Label
    if not parentFrame.cluesHeader then
        local hdr = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        hdr:SetJustifyH("LEFT")
        parentFrame.cluesHeader = hdr
    end
    local cluesHeader = parentFrame.cluesHeader
    cluesHeader:ClearAllPoints()
    if synBox:IsShown() then
        cluesHeader:SetPoint("TOPLEFT", synBox, "BOTTOMLEFT", 0, -16)
    else
        cluesHeader:SetPoint("TOPLEFT", entryStoryFS, "BOTTOMLEFT", 0, -18)
    end
    cluesHeader:SetPoint("RIGHT", parentFrame, "RIGHT", -10, 0)
    cluesHeader:SetText(string.format("Uncovered Evidence & Clues (%d / %d Found)", unlockedCluesCount, totalCluesCount))

    if isDark then
        cluesHeader:SetTextColor(0.95, 0.80, 0.45)
        cluesHeader:SetShadowColor(0, 0, 0, 1)
        cluesHeader:SetShadowOffset(1, -1)
    else
        cluesHeader:SetTextColor(0.32, 0.14, 0.04)
        cluesHeader:SetShadowColor(0, 0, 0, 0)
        cluesHeader:SetShadowOffset(0, 0)
    end
    cluesHeader:Show()

    currentOffsetY = currentOffsetY + 28

    -- Empty state notice
    if not parentFrame.emptyNotice then
        local notice = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        notice:SetJustifyH("LEFT")
        notice:SetSpacing(3)
        parentFrame.emptyNotice = notice
    end
    local emptyNotice = parentFrame.emptyNotice

    if totalCluesCount == 0 then
        emptyNotice:ClearAllPoints()
        emptyNotice:SetPoint("TOPLEFT", cluesHeader, "BOTTOMLEFT", 0, -10)
        emptyNotice:SetPoint("RIGHT", parentFrame, "RIGHT", -10, 0)
        emptyNotice:SetText("No matching field evidence uncovered yet.\nExplore Azeroth, read ancient tomes, complete quests, and speak with key figures to piece together this dossier!")
        if isDark then
            emptyNotice:SetTextColor(0.60, 0.60, 0.65)
        else
            emptyNotice:SetTextColor(0.45, 0.35, 0.22)
        end
        emptyNotice:Show()
        currentOffsetY = currentOffsetY + 55
    else
        emptyNotice:Hide()
    end

    -- Hide all existing buttons
    for i = 1, #clueButtons do
        clueButtons[i]:Hide()
    end

    -- Sort unlocked clues first, followed by locked clues
    local sortedClues = {}
    for _, cKey in ipairs(allClues) do
        table.insert(sortedClues, cKey)
    end
    table.sort(sortedClues, function(aKey, bKey)
        local aEntry = ns.LoreByKey and ns.LoreByKey[aKey]
        local bEntry = ns.LoreByKey and ns.LoreByKey[bKey]
        local aUnlocked = (aEntry and ns.IsEntryUnlocked and ns.IsEntryUnlocked(aEntry)) and 1 or 0
        local bUnlocked = (bEntry and ns.IsEntryUnlocked and ns.IsEntryUnlocked(bEntry)) and 1 or 0
        if aUnlocked ~= bUnlocked then
            return aUnlocked > bUnlocked
        end
        local aTitle = (aEntry and aEntry.title) or aKey
        local bTitle = (bEntry and bEntry.title) or bKey
        return aTitle:lower() < bTitle:lower()
    end)

    -- Responsive Grid Calculation:
    local numCols = (availWidth >= 820) and 3 or 2
    local totalCards = math.min(#sortedClues, 40)
    local cardHeight = 40
    local gapX = 10
    local gapY = 8
    local cardWidth = math.floor((availWidth - (gapX * (numCols - 1))) / numCols)

    for i = 1, totalCards do
        local clueKey = sortedClues[i]
        local clueEntry = ns.LoreByKey and ns.LoreByKey[clueKey]
        local isClueUnlocked = clueEntry and ns.IsEntryUnlocked and ns.IsEntryUnlocked(clueEntry)
        local isRedacted = isSpoilerFree and not isClueUnlocked
        local btn = EnsureClueButton(parentFrame, i)

        local colIndex = (i - 1) % numCols
        local rowIndex = math.floor((i - 1) / numCols)
        local x = colIndex * (cardWidth + gapX)
        local y = currentOffsetY + (rowIndex * (cardHeight + gapY))

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", x, -y)
        btn:SetSize(cardWidth, cardHeight)
        btn.clueKey = clueKey
        btn.isRedacted = isRedacted
        local zoneName = (clueEntry and (clueEntry.zone or clueEntry.era or "Azeroth")) or "Azeroth"
        btn.clueZone = zoneName

        if isRedacted then
            -- REDACTED MYSTERY CARD
            btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            btn.icon:SetDesaturated(true)
            btn.icon:SetVertexColor(0.55, 0.50, 0.45, 0.85)

            btn.title:SetText("Undiscovered Field Clue")
            local catStr = (clueEntry and clueEntry.category) or "Lore"
            btn.meta:SetText(string.format("Unfound %s  |  %s", catStr, zoneName))

            if btn.arrow then btn.arrow:Hide() end

            if isDark then
                btn:SetBackdropColor(0.08, 0.07, 0.07, 0.90)
                btn:SetBackdropBorderColor(0.35, 0.28, 0.18, 0.60)
                btn.title:SetTextColor(0.58, 0.54, 0.50)
                btn.title:SetShadowColor(0, 0, 0, 1)
                btn.title:SetShadowOffset(1, -1)
                btn.meta:SetTextColor(0.48, 0.45, 0.42)
                btn.meta:SetShadowColor(0, 0, 0, 1)
                btn.meta:SetShadowOffset(1, -1)
            else
                btn:SetBackdropColor(0.80, 0.73, 0.60, 0.90)
                btn:SetBackdropBorderColor(0.50, 0.40, 0.25, 0.60)
                btn.title:SetTextColor(0.52, 0.44, 0.36)
                btn.title:SetShadowColor(0, 0, 0, 0)
                btn.title:SetShadowOffset(0, 0)
                btn.meta:SetTextColor(0.50, 0.42, 0.35)
                btn.meta:SetShadowColor(0, 0, 0, 0)
                btn.meta:SetShadowOffset(0, 0)
            end
        else
            -- FULL UNLOCKED / SHOWN EVIDENCE CARD
            if btn.arrow then btn.arrow:Show() end

            if isDark then
                btn:SetBackdropColor(0.12, 0.10, 0.09, 0.95)
                btn:SetBackdropBorderColor(0.55, 0.42, 0.22, 0.85)
                btn.title:SetTextColor(0.95, 0.92, 0.85)
                btn.title:SetShadowColor(0, 0, 0, 1)
                btn.title:SetShadowOffset(1, -1)
                btn.meta:SetTextColor(0.65, 0.70, 0.78)
                btn.meta:SetShadowColor(0, 0, 0, 1)
                btn.meta:SetShadowOffset(1, -1)
            else
                btn:SetBackdropColor(0.84, 0.77, 0.63, 0.95)
                btn:SetBackdropBorderColor(0.62, 0.48, 0.28, 0.90)
                btn.title:SetTextColor(0.16, 0.10, 0.05)
                btn.title:SetShadowColor(0, 0, 0, 0)
                btn.title:SetShadowOffset(0, 0)
                btn.meta:SetTextColor(0.42, 0.30, 0.18)
                btn.meta:SetShadowColor(0, 0, 0, 0)
                btn.meta:SetShadowOffset(0, 0)
            end

            if clueEntry then
                local iconPath = clueEntry.icon
                    or (ns.CategoryIcons and ns.CategoryIcons[clueEntry.category])
                    or "Interface\\Icons\\INV_Misc_Book_09"
                btn.icon:SetTexture(iconPath)
                btn.icon:SetDesaturated(false)
                btn.icon:SetVertexColor(1.0, 1.0, 1.0, 1.0)

                local tag = (ns.CategoryTags and ns.CategoryTags[clueEntry.category]) or ""
                local prefix = (tag ~= "") and (tag .. " ") or ""
                btn.title:SetText(prefix .. (clueEntry.title or clueKey))

                local zoneStr = clueEntry.zone or "Azeroth"
                local catStr = clueEntry.category or "Lore"
                local stateTag = isClueUnlocked and "|cff4cd964Verified|r" or "|cffaa9977Unverified|r"
                if not isDark and isClueUnlocked then
                    stateTag = "|cff1b6e2bVerified|r"
                elseif not isDark then
                    stateTag = "|cff6e5a42Unverified|r"
                end
                btn.meta:SetText(string.format("%s  •  %s  •  %s", catStr, zoneStr, stateTag))
            else
                btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                btn.icon:SetDesaturated(false)
                btn.icon:SetVertexColor(1.0, 1.0, 1.0, 1.0)
                btn.title:SetText(clueKey)
                btn.meta:SetText("Harvested Clue")
            end
        end

        btn:Show()
    end

    local numRows = math.ceil(totalCards / numCols)
    currentOffsetY = currentOffsetY + (numRows * (cardHeight + gapY))

    return currentOffsetY + 24
end

function ns.HideDossierClues()
    for _, btn in ipairs(clueButtons) do
        btn:Hide()
    end
    local main = ChronicleWeaverMainFrame
    if main and main.readerPanel and main.readerPanel.storyScrollChild then
        local child = main.readerPanel.storyScrollChild
        if child.caseHeaderBox then child.caseHeaderBox:Hide() end
        if child.synthesisBox then child.synthesisBox:Hide() end
        if child.cluesHeader then child.cluesHeader:Hide() end
        if child.emptyNotice then child.emptyNotice:Hide() end
        if main.readerPanel.entryStory then
            main.readerPanel.entryStory:ClearAllPoints()
            main.readerPanel.entryStory:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
            main.readerPanel.entryStory:SetPoint("TOPRIGHT", child, "TOPRIGHT", -4, 0)
        end
    end
end
