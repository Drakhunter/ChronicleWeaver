-- =========================================================================
-- UI/ReaderView.lua
-- Right-hand Tome Reader with Layered Parchment, Filigree & Medallion Frame.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

local main = ChronicleWeaverMainFrame
local readerPanel = main and main.readerPanel

if not readerPanel then
    error("ChronicleWeaver: readerPanel missing in MainFrame.")
end

-- -------------------------------------------------------------------------
-- Helper: Crimson Parchment Highlight Generator
-- -------------------------------------------------------------------------
function ns.HighlightForParchment(text)
    if not text or type(text) ~= "string" then return text or "" end
    -- Replace bright yellow |cffffd100 highlight tokens with Deep Crimson Bronze (|cff7a1c14)
    return text:gsub("|cffffd100", "|cff7a1c14")
end

-- -------------------------------------------------------------------------
-- Layered Vignette Texture (Aged Page Edges)
-- -------------------------------------------------------------------------
local vignette = readerPanel:CreateTexture(nil, "BORDER", nil, 1)
vignette:SetAllPoints(readerPanel)
vignette:SetTexture(ns.MediaPath .. "bg_parchment_vignette")
vignette:SetAlpha(0.65)
readerPanel.vignette = vignette

-- -------------------------------------------------------------------------
-- Helper: Custom Journal Action Button
-- -------------------------------------------------------------------------
local function CreateJournalActionButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.14, 0.11, 0.09, 0.95)
    btn:SetBackdropBorderColor(0.48, 0.36, 0.22, 1.0)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.85, 0.68, 0.35, 0.18)

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetTextColor(0.92, 0.85, 0.72)
    fs:SetText(text or "")
    btn.text = fs
    btn.SetText = function(self, t) self.text:SetText(t) end
    btn.GetText = function(self) return self.text:GetText() end

    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.24, 0.18, 0.12, 1.0)
        self:SetBackdropBorderColor(0.85, 0.70, 0.35, 1.0)
        self.text:SetTextColor(1.0, 0.95, 0.85)
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.14, 0.11, 0.09, 0.95)
        self:SetBackdropBorderColor(0.48, 0.36, 0.22, 1.0)
        self.text:SetTextColor(0.92, 0.85, 0.72)
    end)

    return btn
end

-- -------------------------------------------------------------------------
-- 1. Portrait Header Card & Action Buttons
-- -------------------------------------------------------------------------
-- 44x44 Portrait Icon
local portraitFrame = CreateFrame("Frame", "ChronicleWeaverReaderPortrait", readerPanel, "BackdropTemplate")
portraitFrame:SetSize(44, 44)
portraitFrame:SetPoint("TOPLEFT", 14, -12)

local portraitTex = portraitFrame:CreateTexture(nil, "ARTWORK")
portraitTex:SetPoint("TOPLEFT", 2, -2)
portraitTex:SetPoint("BOTTOMRIGHT", -2, 2)
portraitTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
readerPanel.portraitFrame = portraitFrame
readerPanel.portraitTex = portraitTex

-- Ornate 56x56 Medallion Ring Frame Overlay (Centered, Aspect-Correct)
local portraitRing = portraitFrame:CreateTexture(nil, "OVERLAY")
portraitRing:SetSize(56, 56)
portraitRing:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
portraitRing:SetTexture(ns.MediaPath .. "frame_portrait_ring")
portraitRing:SetVertexColor(0.92, 0.82, 0.55, 1.0)
readerPanel.portraitRing = portraitRing

-- Map Pin Action Button
local pinBtn = CreateJournalActionButton(readerPanel, 90, 22, "Pin to Map")
pinBtn:SetPoint("TOPRIGHT", -14, -14)
pinBtn:Hide()
pinBtn:SetScript("OnClick", function()
    local entry = ns.selectedKey and ns.LoreByKey and ns.LoreByKey[ns.selectedKey]
    if entry and entry.mapID and entry.x and entry.y and ns.SetMapPin then
        ns.SetMapPin(entry.mapID, entry.x, entry.y, entry.title or "Lore Location")
        if ns.Print then
            ns.Print("Pinned location for: |cffffd100" .. (entry.title or entry.key) .. "|r")
        end
    end
end)
pinBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("World Map Pin", 1, 0.82, 0.45)
    GameTooltip:AddLine("Set a navigational waypoint to this chronicle's origin location.", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end)
pinBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
readerPanel.pinBtn = pinBtn

-- Delete Harvested Entry Action Button
local deleteBtn = CreateJournalActionButton(readerPanel, 70, 22, "Delete")
deleteBtn:SetPoint("RIGHT", pinBtn, "LEFT", -6, 0)
deleteBtn:Hide()
deleteBtn:SetScript("OnClick", function()
    if not ns.selectedKey then return end
    StaticPopupDialogs["CHRONICLEWEAVER_CONFIRM_DELETE"] = {
        text = "Permanently remove this harvested entry from your archive?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            if ns.selectedKey and ns.DeleteHarvestedEntry then
                ns.DeleteHarvestedEntry(ns.selectedKey)
                ns.selectedKey = nil
                if ns.RefreshUI then ns.RefreshUI() end
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("CHRONICLEWEAVER_CONFIRM_DELETE")
end)
readerPanel.deleteBtn = deleteBtn

-- Heading FontString
local entryHeading = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
entryHeading:SetPoint("TOPLEFT", portraitFrame, "TOPRIGHT", 14, -2)
entryHeading:SetPoint("RIGHT", pinBtn, "LEFT", -8, 0)
entryHeading:SetJustifyH("LEFT")
entryHeading:SetWordWrap(false)
readerPanel.entryHeading = entryHeading

-- Meta FontString (Category | Era/Zone | Discovery Status)
local entryMeta = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
entryMeta:SetPoint("TOPLEFT", entryHeading, "BOTTOMLEFT", 0, -3)
entryMeta:SetTextColor(0.65, 0.75, 0.85)
readerPanel.entryMeta = entryMeta

-- Summary FontString
local entrySummary = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
entrySummary:SetPoint("TOPLEFT", portraitFrame, "BOTTOMLEFT", 0, -10)
entrySummary:SetPoint("RIGHT", -14, 0)
entrySummary:SetJustifyH("LEFT")
entrySummary:SetTextColor(0.95, 0.85, 0.55)
readerPanel.entrySummary = entrySummary

-- Non-Distorting Filigree Divider Container with Extending Gold Wings
local dividerContainer = CreateFrame("Frame", nil, readerPanel)
dividerContainer:SetPoint("TOPLEFT", entrySummary, "BOTTOMLEFT", 6, -8)
dividerContainer:SetPoint("TOPRIGHT", entrySummary, "BOTTOMRIGHT", -6, -8)
dividerContainer:SetHeight(20)
readerPanel.dividerContainer = dividerContainer

local divider = dividerContainer:CreateTexture(nil, "ARTWORK")
divider:SetSize(420, 24)
divider:SetPoint("CENTER", dividerContainer, "CENTER", 0, 0)
divider:SetTexture(ns.MediaPath .. "divider_filigree")
divider:SetVertexColor(0.85, 0.68, 0.35, 0.90)
readerPanel.divider = divider

local dividerLineL = dividerContainer:CreateTexture(nil, "BORDER")
dividerLineL:SetPoint("LEFT", dividerContainer, "LEFT", 10, 0)
dividerLineL:SetPoint("RIGHT", divider, "LEFT", -4, 0)
dividerLineL:SetHeight(1)
dividerLineL:SetColorTexture(0.83, 0.66, 0.35, 0.45)
readerPanel.dividerLineL = dividerLineL

local dividerLineR = dividerContainer:CreateTexture(nil, "BORDER")
dividerLineR:SetPoint("LEFT", divider, "RIGHT", 4, 0)
dividerLineR:SetPoint("RIGHT", dividerContainer, "RIGHT", -10, 0)
dividerLineR:SetHeight(1)
dividerLineR:SetColorTexture(0.83, 0.66, 0.35, 0.45)
readerPanel.dividerLineR = dividerLineR

-- -------------------------------------------------------------------------
-- 2. Personal Field Notes Drawer (Auto-Saving)
-- -------------------------------------------------------------------------
local notesLabel = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
notesLabel:SetPoint("BOTTOMLEFT", 14, 60)
notesLabel:SetText("Personal Field Notes (Auto-Saved):")
readerPanel.notesLabel = notesLabel

local notesBg = CreateFrame("Frame", nil, readerPanel, "BackdropTemplate")
notesBg:SetPoint("BOTTOMLEFT", 14, 10)
notesBg:SetPoint("BOTTOMRIGHT", -14, 10)
notesBg:SetHeight(46)
notesBg:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
readerPanel.notesBg = notesBg

local notesBox = CreateFrame("EditBox", nil, notesBg)
notesBox:SetMultiLine(true)
notesBox:SetFontObject("ChatFontNormal")
notesBox:SetPoint("TOPLEFT", 8, -6)
notesBox:SetPoint("BOTTOMRIGHT", -8, 6)
notesBox:SetAutoFocus(false)
notesBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
notesBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput and ns.selectedKey and ns.db and ns.db.notes then
        ns.db.notes[ns.selectedKey] = self:GetText()
    end
end)
readerPanel.notesBox = notesBox

-- -------------------------------------------------------------------------
-- 3. Fluid Connected Lore & Backlinks Pills Bar
-- -------------------------------------------------------------------------
local connLabel = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
connLabel:SetPoint("BOTTOMLEFT", 14, 114)
connLabel:SetText("Connected Lore & Mentioned In:")
readerPanel.connLabel = connLabel

local connPills = {}
for i = 1, 6 do
    local pill = CreateJournalActionButton(readerPanel, 96, 20, "")
    pill:Hide()
    pill:SetScript("OnClick", function(self)
        if self.targetKey and ns.SelectEntry then
            ns.SelectEntry(self.targetKey)
        end
    end)
    connPills[i] = pill
end
readerPanel.connPills = connPills

-- -------------------------------------------------------------------------
-- 4. Scrollable Story Area (UIPanelScrollFrameTemplate) with Wheel Forwarding
-- -------------------------------------------------------------------------
local storyScrollFrame = CreateFrame("ScrollFrame", "ChronicleWeaverStoryScrollFrame", readerPanel, "UIPanelScrollFrameTemplate")
storyScrollFrame:SetPoint("TOPLEFT", dividerContainer, "BOTTOMLEFT", -6, -8)
storyScrollFrame:SetPoint("BOTTOMRIGHT", readerPanel, "BOTTOMRIGHT", -26, 134)

local storyScrollChild = CreateFrame("Frame", nil, storyScrollFrame)
storyScrollChild:SetSize(380, 1)
storyScrollFrame:SetScrollChild(storyScrollChild)
readerPanel.storyScrollChild = storyScrollChild

storyScrollFrame:SetScript("OnSizeChanged", function(self, width)
    if width and width > 0 then
        storyScrollChild:SetWidth(width)
    end
end)

-- Forward Mouse-Wheel Scrolling
function ns.ScrollStoryByDelta(delta)
    if not storyScrollFrame then return end
    local cur = storyScrollFrame:GetVerticalScroll() or 0
    local step = 32
    local maxRange = storyScrollFrame:GetVerticalScrollRange() or 0
    local newScroll = math.max(0, math.min(maxRange, cur - (delta * step)))
    storyScrollFrame:SetVerticalScroll(newScroll)
end

storyScrollFrame:EnableMouseWheel(true)
storyScrollFrame:SetScript("OnMouseWheel", function(_, delta)
    ns.ScrollStoryByDelta(delta)
end)

storyScrollChild:EnableMouseWheel(true)
storyScrollChild:SetScript("OnMouseWheel", function(_, delta)
    ns.ScrollStoryByDelta(delta)
end)

local entryStory = storyScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
entryStory:SetPoint("TOPLEFT", storyScrollChild, "TOPLEFT", 0, 0)
entryStory:SetPoint("TOPRIGHT", storyScrollChild, "TOPRIGHT", -4, 0)
entryStory:SetJustifyH("LEFT")
entryStory:SetSpacing(4) -- Generous reading line spacing
readerPanel.entryStory = entryStory

-- Manual Unlock Button for undiscovered entries in spoiler mode
local revealBtn = CreateJournalActionButton(storyScrollChild, 160, 24, "Reveal Lore Entry")
revealBtn:SetPoint("TOPLEFT", entryStory, "BOTTOMLEFT", 0, -14)
revealBtn:Hide()
revealBtn:SetScript("OnClick", function()
    if ns.selectedKey then
        ns.UnlockEntry(ns.selectedKey)
        if ns.RefreshUI then ns.RefreshUI() end
    end
end)
readerPanel.revealBtn = revealBtn

-- -------------------------------------------------------------------------
-- 5. Refresh Reader View
-- -------------------------------------------------------------------------
function ns.RefreshReaderView()
    local entry = ns.selectedKey and ns.LoreByKey and ns.LoreByKey[ns.selectedKey]
    local isDark = (ns.db and ns.db.theme == "DARK")

    if not entry then
        portraitFrame:Hide()
        entryHeading:SetText("No Chronicle Selected")
        entryMeta:SetText("")
        if ns.db and ns.db.spoilerFree then
            entrySummary:SetText("No Discovered Chronicles in this category yet — explore Azeroth or toggle Spoilers: Shown")
        else
            entrySummary:SetText("Select an entry from the left index to read its lore.")
        end
        entryStory:SetText("")
        pinBtn:Hide()
        deleteBtn:Hide()
        revealBtn:Hide()
        connLabel:Hide()
        for i = 1, 6 do connPills[i]:Hide() end
        notesBox:SetText("")
        storyScrollChild:SetHeight(1)
        if ns.HideDossierClues then ns.HideDossierClues() end
        return
    end

    local isUnlocked = ns.IsEntryUnlocked and ns.IsEntryUnlocked(entry)
    local isSpoilerFree = (ns.db and ns.db.spoilerFree == true)

    -- Auto-discover Dossiers if at least 1 clue is discovered
    if entry.category == "Dossier" and not (ns.db and ns.db.discovered and ns.db.discovered[entry.key]) then
        if isUnlocked and ns.db and ns.db.discovered then
            ns.db.discovered[entry.key] = time()
        end
    end

    -- Portrait Icon
    local iconPath = entry.icon
        or (ns.CategoryIcons and ns.CategoryIcons[entry.category])
        or "Interface\\Icons\\INV_Misc_Book_09"
    portraitTex:SetTexture(iconPath)
    portraitFrame:Show()

    -- Title & Heading
    local title = entry.title or entry.key
    entryHeading:SetText(title)

    -- Metadata Badges (Category | Era/Zone | Discovery Status)
    local regionStr = entry.era or entry.zone or "Azeroth"
    local statusStr
    if isDark then
        statusStr = isUnlocked and "|cff4cd964Discovered|r" or "|cff888888Undiscovered|r"
    else
        statusStr = isUnlocked and "|cff1b6e2bDiscovered|r" or "|cff5c5245Undiscovered|r"
    end
    entryMeta:SetText(string.format("%s  |  %s  |  %s", entry.category, regionStr, statusStr))

    -- Summary
    if not isUnlocked and isSpoilerFree and entry.category ~= "Dossier" then
        entrySummary:SetText("The details of this chronicle remain hidden. Explore Azeroth to uncover its secrets.")
    else
        entrySummary:SetText(entry.summary or "")
    end

    -- Action Button: Pin to Map
    local hasCoords = (entry.mapID and entry.x and entry.x > 0)
    if hasCoords then
        pinBtn:Show()
    else
        pinBtn:Hide()
    end

    -- Action Button: Delete
    local isHarvested = (entry.category == "Book")
        or (entry.category == "Quest")
        or (ns.db and ns.db.books and ns.db.books[entry.key])
        or (ns.db and ns.db.quests and ns.db.quests[entry.key])
        or (ns.db and ns.db.items and ns.db.items[entry.key])
        or (ns.db and ns.db.gossip and ns.db.gossip[entry.key])

    if isHarvested then
        deleteBtn:ClearAllPoints()
        if hasCoords then
            deleteBtn:SetPoint("RIGHT", pinBtn, "LEFT", -6, 0)
        else
            deleteBtn:SetPoint("TOPRIGHT", -14, -14)
        end
        deleteBtn:Show()
    else
        deleteBtn:Hide()
    end

    -- Field Notes
    notesBox:SetText((ns.db and ns.db.notes and ns.db.notes[entry.key]) or "")

    -- Story / Dossier Evidence Board View
    storyScrollFrame:SetVerticalScroll(0)

    if entry.category == "Dossier" and ns.RenderDossierView then
        revealBtn:Hide()
        -- Parent Dossier Evidence Cards directly inside storyScrollChild
        local totalHeight = ns.RenderDossierView(storyScrollChild, entry, entryStory)
        storyScrollChild:SetHeight(math.max(160, totalHeight))

        -- Hide redundant bottom connected pills bar when viewing a Dossier!
        connLabel:Hide()
        for i = 1, 6 do connPills[i]:Hide() end
    else
        if ns.HideDossierClues then ns.HideDossierClues() end

        if not isUnlocked and isSpoilerFree then
            entryStory:SetText("This chapter is sealed under Spoiler-Safe mode.\n\nInteract with the subject in-game or click the button below to manually reveal this entry.")
            revealBtn:ClearAllPoints()
            revealBtn:SetPoint("TOPLEFT", entryStory, "BOTTOMLEFT", 0, -14)
            revealBtn:Show()
            storyScrollChild:SetHeight(120)
        else
            revealBtn:Hide()
            local storyText = entry.story or "No written narrative recorded for this chronicle."
            if ns.WeaveTextConnections then
                storyText, _ = ns.WeaveTextConnections(storyText)
            end
            if isSpoilerFree then
                storyText = storyText:gsub("|c%x%x%x%x%x%x%x%x%[(.-)%]|r", function(word)
                    local candidates = ns.BuildWeavableCandidates and ns.BuildWeavableCandidates()
                    if candidates then
                        local lword = word:lower()
                        for _, cand in ipairs(candidates) do
                            if cand.phrase:lower() == lword then
                                local target = ns.LoreByKey and ns.LoreByKey[cand.key]
                                if target and not (ns.IsEntryUnlocked and ns.IsEntryUnlocked(target)) then
                                    return word
                                end
                            end
                        end
                    end
                end)
            end
            if not isDark and ns.HighlightForParchment then
                storyText = ns.HighlightForParchment(storyText)
            end
            entryStory:SetText(storyText)
            local stringHeight = entryStory:GetStringHeight() or 80
            storyScrollChild:SetHeight(math.max(100, stringHeight + 30))
        end

        -- Fluid Connected Lore & Backlinks Pills Bar (shown for non-dossier entries)
        local rawConnected = (ns.GetConnectedLore and ns.GetConnectedLore(entry.key)) or entry.related or {}
        local connectedKeys = {}
        for _, relKey in ipairs(rawConnected) do
            local targetEntry = ns.LoreByKey and ns.LoreByKey[relKey]
            if not isSpoilerFree or (targetEntry and ns.IsEntryUnlocked and ns.IsEntryUnlocked(targetEntry)) then
                table.insert(connectedKeys, relKey)
            end
        end
        for i = 1, 6 do connPills[i]:Hide() end

        if #connectedKeys > 0 then
            connLabel:Show()
            local maxPills = math.min(#connectedKeys, 6)
            local panelW = readerPanel:GetWidth() or 600
            local labelW = connLabel:GetStringWidth() or 180
            local availPillWidth = panelW - labelW - 36
            local pillGap = 6
            local pillWidth = math.max(68, math.min(130, math.floor((availPillWidth - ((maxPills - 1) * pillGap)) / maxPills)))

            for i = 1, maxPills do
                local cKey = connectedKeys[i]
                local cEntry = ns.LoreByKey and ns.LoreByKey[cKey]
                local pill = connPills[i]
                pill.targetKey = cKey
                pill:SetSize(pillWidth, 20)
                pill:ClearAllPoints()
                if i == 1 then
                    pill:SetPoint("LEFT", connLabel, "RIGHT", 8, 0)
                else
                    pill:SetPoint("LEFT", connPills[i - 1], "RIGHT", pillGap, 0)
                end

                local shortTitle = cKey
                local tag = "[*]"
                if cEntry then
                    shortTitle = cEntry.title or cKey
                    tag = (ns.CategoryTags and ns.CategoryTags[cEntry.category]) or "[*]"
                end

                local charLimit = math.max(8, math.floor(pillWidth / 9))
                if #shortTitle > charLimit then
                    shortTitle = shortTitle:sub(1, charLimit - 1) .. "..."
                end

                pill:SetText(tag .. " " .. shortTitle)
                pill:Show()
            end
        else
            connLabel:Hide()
        end
    end
end
