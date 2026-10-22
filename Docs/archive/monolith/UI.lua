local addonName, ns = ...

local activeCategory = "ALL"
local searchQuery = ""
local selectedKey = nil
local prevSelectedKey = nil
local listButtons = {}
local listScrollOffset = 0
local filteredCount = 0

-- Forward declarations
local storyScrollFrame

-- Confirmation dialog for deleting harvested books (Step 2.4)
StaticPopupDialogs["CHRONICLEWEAVER_DELETE_BOOK"] = {
    text = "Are you sure you want to delete '%s' from your Lore Codex",
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(self, data)
        if data and ns.DeleteSavedBook then
            ns.DeleteSavedBook(data)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ==========================================
-- 1. DISCOVERY TOAST BANNER
-- ==========================================
local toast = CreateFrame("Button", "ChronicleWeaverToastFrame", UIParent, "BackdropTemplate")
toast:SetSize(320, 58)
toast:SetPoint("TOP", 0, -120)
toast:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
toast:SetBackdropColor(0.08, 0.07, 0.06, 0.94)
toast:SetBackdropBorderColor(0.83, 0.66, 0.35, 1)
toast:Hide()

local toastHeader = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
toastHeader:SetPoint("TOPLEFT", 14, -10)
toastHeader:SetText("|cffd4a85aNEW LORE DISCOVERED|r")

local toastTitle = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
toastTitle:SetPoint("TOPLEFT", toastHeader, "BOTTOMLEFT", 0, -4)
toastTitle:SetPoint("RIGHT", -14, 0)
toastTitle:SetJustifyH("LEFT")

toast:SetScript("OnClick", function(self)
    if self.entryKey then
        if selectedKey ~= self.entryKey then
            selectedKey = self.entryKey
            if storyScrollFrame then
                storyScrollFrame:SetVerticalScroll(0)
            end
        end
        ns.ToggleMainFrame(true)
        ns.RefreshUI()
    end
    self:Hide()
end)

function ns.ShowDiscoveryToast(entry, isSynthesis)
    if not entry then return end
    toast.entryKey = entry.key
    toastTitle:SetText(entry.title or "Unknown")

    if isSynthesis or entry.category == "Deduction" then
        toast:SetBackdropBorderColor(0.77, 0.52, 0.75, 1) -- Distinct purple border
        toastHeader:SetText("|cffc586c0LORE DEDUCTION SYNTHESIZED|r")
    else
        toast:SetBackdropBorderColor(0.83, 0.66, 0.35, 1) -- Classic gold border
        toastHeader:SetText("|cffd4a85aNEW LORE DISCOVERED|r")
    end

    toast:Show()
    C_Timer.After(6, function()
        if toast:IsShown() and toast.entryKey == entry.key then
            toast:Hide()
        end
    end)
end

-- ==========================================
-- 2. MAIN CODEX WINDOW
-- ==========================================
local main = CreateFrame("Frame", "ChronicleWeaverMainFrame", UIParent, "BackdropTemplate")
main:SetSize(960, 640)
main:SetPoint("CENTER")
main:SetMovable(true)
main:SetResizable(true)
main:SetResizeBounds(780, 500, 1400, 950)
main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
})
main:SetBackdropColor(0.09, 0.08, 0.07, 0.96)
main:Hide()
tinsert(UISpecialFrames, "ChronicleWeaverMainFrame")

-- Combat-lockdown safe dragging and resizing
main:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then self:StartMoving() end
end)
main:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if ns.db and not InCombatLockdown() then
        local point, _, relPoint, x, y = self:GetPoint()
        local width, height = self:GetSize()
        ns.db.windowPos = { point = point, relPoint = relPoint, x = x, y = y, width = width, height = height }
    end
end)

-- Resize Grip Button in Bottom-Right
local resizeGrip = CreateFrame("Button", nil, main)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", -6, 6)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:SetScript("OnMouseDown", function()
    if not InCombatLockdown() then
        main:StartSizing("BOTTOMRIGHT")
    end
end)
resizeGrip:SetScript("OnMouseUp", function()
    main:StopMovingOrSizing()
    if ns.db and not InCombatLockdown() then
        local point, _, relPoint, x, y = main:GetPoint()
        local width, height = main:GetSize()
        ns.db.windowPos = { point = point, relPoint = relPoint, x = x, y = y, width = width, height = height }
    end
end)

function ns.RestoreWindowPosition()
    if ns.db and ns.db.windowPos and not InCombatLockdown() then
        local pos = ns.db.windowPos
        main:ClearAllPoints()
        main:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
        if pos.width and pos.height then
            main:SetSize(pos.width, pos.height)
        else
            main:SetSize(960, 640)
        end
    end
end

-- Header Title
local titleText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 18, -16)
titleText:SetText("|cffd4a85aChronicleWeaver|r   WoW: Forever Lore Codex")

-- Close Button
local closeBtn = CreateFrame("Button", nil, main, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -6, -6)

-- Header Filter & Toggle Buttons
local spoilerBtn = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
spoilerBtn:SetSize(125, 22)
spoilerBtn:SetPoint("TOPRIGHT", -40, -14)
spoilerBtn:SetScript("OnClick", function()
    if ns.db then
        ns.db.spoilerFree = not ns.db.spoilerFree
        ns.RefreshUI()
    end
end)
spoilerBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Spoiler Protection", 1, 0.82, 0.45)
    GameTooltip:AddLine("Click to toggle spoiler protection on or off.", 0.85, 0.85, 0.85)
    GameTooltip:Show()
end)
spoilerBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local factionBtn = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
factionBtn:SetSize(125, 22)
factionBtn:SetPoint("RIGHT", spoilerBtn, "LEFT", -6, 0)
factionBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
factionBtn:SetScript("OnClick", function(_, button)
    if not ns.db then return end
    if button == "RightButton" then
        ns.db.factionFilter = "ALL"
    else
        local cur = ns.db.factionFilter or "ALL"
        if cur == "ALL" then
            ns.db.factionFilter = "Alliance"
        elseif cur == "Alliance" then
            ns.db.factionFilter = "Horde"
        elseif cur == "Horde" then
            ns.db.factionFilter = "Neutral"
        else
            ns.db.factionFilter = "ALL"
        end
    end
    listScrollOffset = 0
    ns.RefreshUI()
end)
factionBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Faction Filter", 1, 0.82, 0.45)
    GameTooltip:AddLine("Left-Click: Cycle All -> Alliance -> Horde -> Neutral", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Right-Click: Reset filter to All", 0.65, 0.65, 0.65)
    GameTooltip:Show()
end)
factionBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local charBtn = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
charBtn:SetSize(130, 22)
charBtn:SetPoint("RIGHT", factionBtn, "LEFT", -6, 0)
charBtn:SetScript("OnClick", function()
    if not ns.db then return end
    if ns.db.charFilter == "CURRENT" then
        ns.db.charFilter = "ALL"
    else
        ns.db.charFilter = "CURRENT"
    end
    listScrollOffset = 0
    ns.RefreshUI()
end)
charBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Character Filter", 1, 0.82, 0.45)
    local curChar = ns.GetPlayerKey and ns.GetPlayerKey() or "Current"
    GameTooltip:AddLine("Click to toggle between All Characters and " .. curChar .. ".", 0.85, 0.85, 0.85)
    GameTooltip:Show()
end)
charBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Category Filter Bar (8 tabs: ALL, Zone, Dungeon, NPC, Relic, Book, Quest, Deduction)
local categories = { "ALL", "Zone", "Dungeon", "NPC", "Relic", "Book", "Quest", "Deduction" }
local catWidths = {
    ALL = 38,
    Zone = 44,
    Dungeon = 58,
    NPC = 42,
    Relic = 46,
    Book = 46,
    Quest = 48,
    Deduction = 70,
}
local catButtons = {}
local currentX = 16
for _, cat in ipairs(categories) do
    local width = catWidths[cat] or 48
    local btn = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
    btn:SetSize(width, 22)
    btn:SetPoint("TOPLEFT", currentX, -44)
    btn:SetText(cat)
    btn:SetScript("OnClick", function()
        activeCategory = cat
        listScrollOffset = 0
        ns.RefreshUI()
    end)
    catButtons[cat] = btn
    currentX = currentX + width + 4
end

-- Search Box
local searchBox = CreateFrame("EditBox", nil, main, "InputBoxTemplate")
searchBox:SetSize(165, 22)
searchBox:SetPoint("TOPRIGHT", -16, -44)
searchBox:SetAutoFocus(false)
searchBox:SetTextInsets(6, 6, 0, 0)
searchBox:SetScript("OnTextChanged", function(self)
    searchQuery = (self:GetText() or ""):lower()
    listScrollOffset = 0
    ns.RefreshUI()
end)
searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

local searchLabel = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("RIGHT", searchBox, "LEFT", -6, 0)
searchLabel:SetText("Search:")

-- Left Column: Entry List Panel
local listPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
listPanel:SetPoint("TOPLEFT", 16, -74)
listPanel:SetPoint("BOTTOMLEFT", 16, 16)
listPanel:SetWidth(270)
listPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
listPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.9)

-- Helper: Scroll Entry List with mouse-wheel
local function ScrollEntryList(delta)
    local maxOffset = math.max(0, filteredCount - 21)
    if maxOffset == 0 then return end
    listScrollOffset = math.max(0, math.min(maxOffset, listScrollOffset - delta * 3))
    ns.RefreshUI()
end

listPanel:EnableMouseWheel(true)
listPanel:SetScript("OnMouseWheel", function(_, delta)
    ScrollEntryList(delta)
end)

-- Visual Vertical Scrollbar (Slider) on the right edge of listPanel
local isUpdatingScrollBar = false
local listScrollBar = CreateFrame("Slider", "ChronicleWeaverListScrollBar", listPanel, "BackdropTemplate")
listScrollBar:SetPoint("TOPRIGHT", -6, -10)
listScrollBar:SetPoint("BOTTOMRIGHT", -6, 24)
listScrollBar:SetWidth(8)
listScrollBar:SetOrientation("VERTICAL")

local scrollTrack = listScrollBar:CreateTexture(nil, "BACKGROUND")
scrollTrack:SetAllPoints()
scrollTrack:SetColorTexture(0.04, 0.04, 0.04, 0.8)

local scrollThumb = listScrollBar:CreateTexture(nil, "OVERLAY")
scrollThumb:SetSize(8, 28)
scrollThumb:SetColorTexture(0.83, 0.66, 0.35, 0.85)
listScrollBar:SetThumbTexture(scrollThumb)

listScrollBar:SetMinMaxValues(0, 0)
listScrollBar:SetValueStep(1)
listScrollBar:SetObeyStepOnDrag(true)
listScrollBar:SetValue(0)
listScrollBar:EnableMouseWheel(true)
listScrollBar:SetScript("OnMouseWheel", function(_, delta)
    ScrollEntryList(delta)
end)

listScrollBar:SetScript("OnValueChanged", function(self, value)
    if isUpdatingScrollBar then return end
    isUpdatingScrollBar = true
    local offset = math.floor(value + 0.5)
    if offset ~= listScrollOffset then
        listScrollOffset = offset
        ns.RefreshUI()
    end
    isUpdatingScrollBar = false
end)

-- Small scroll indicator label at the bottom of listPanel
local listScrollIndicator = listPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
listScrollIndicator:SetPoint("BOTTOM", listPanel, "BOTTOM", 0, 7)
listScrollIndicator:SetJustifyH("CENTER")

-- Right Column: Lore Reader & Personal Field Notes
local readerPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
readerPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 10, 0)
readerPanel:SetPoint("BOTTOMRIGHT", -16, 16)
readerPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
readerPanel:SetBackdropColor(0.06, 0.05, 0.04, 0.9)

local entryHeading = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
entryHeading:SetPoint("TOPLEFT", 16, -16)
entryHeading:SetPoint("RIGHT", -190, 0)
entryHeading:SetJustifyH("LEFT")

-- Pin Discovery to World Map Button
local pinBtn = CreateFrame("Button", nil, readerPanel, "UIPanelButtonTemplate")
pinBtn:SetSize(105, 22)
pinBtn:SetPoint("TOPRIGHT", -14, -14)
pinBtn:SetText("Pin to Map")
pinBtn:Hide()
pinBtn:SetScript("OnClick", function()
    if selectedKey then
        ns.PinEntryToMap(selectedKey)
    end
end)

-- Delete Saved Entry Button
local deleteBtn = CreateFrame("Button", nil, readerPanel, "UIPanelButtonTemplate")
deleteBtn:SetSize(65, 22)
deleteBtn:SetPoint("RIGHT", pinBtn, "LEFT", -6, 0)
deleteBtn:SetText("Delete")
deleteBtn:Hide()
deleteBtn:SetScript("OnClick", function()
    if selectedKey and ns.LoreByKey and ns.LoreByKey[selectedKey] then
        local entry = ns.LoreByKey[selectedKey]
        StaticPopup_Show("CHRONICLEWEAVER_DELETE_BOOK", entry.title or "this entry", nil, selectedKey)
    end
end)

local entryMeta = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
entryMeta:SetPoint("TOPLEFT", entryHeading, "BOTTOMLEFT", 0, -4)
entryMeta:SetTextColor(0.65, 0.75, 0.85)

local entrySummary = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
entrySummary:SetPoint("TOPLEFT", entryMeta, "BOTTOMLEFT", 0, -10)
entrySummary:SetPoint("RIGHT", -16, 0)
entrySummary:SetJustifyH("LEFT")
entrySummary:SetTextColor(0.95, 0.85, 0.55)

-- Connected Lore Jump-Chips (Row of 4 clickable buttons)
local relatedLabel = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
relatedLabel:SetPoint("BOTTOMLEFT", 16, 105)
relatedLabel:SetText("|cffd4a85aConnected Lore:|r")
relatedLabel:Hide()

local relatedButtons = {}
for i = 1, 4 do
    local chip = CreateFrame("Button", nil, readerPanel, "UIPanelButtonTemplate")
    chip:SetHeight(20)
    chip:SetWidth(135)
    if i == 1 then
        chip:SetPoint("BOTTOMLEFT", 16, 81)
    else
        chip:SetPoint("LEFT", relatedButtons[i - 1], "RIGHT", 6, 0)
    end
    chip:Hide()
    relatedButtons[i] = chip
end

-- Personal Field Notes Box (Slimmed-down 48px height)
local notesLabel = readerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
notesLabel:SetPoint("BOTTOMLEFT", 16, 63)
notesLabel:SetText("|cffd4a85aPersonal Field Notes (Auto-Saved):|r")

local notesBg = CreateFrame("Frame", nil, readerPanel, "BackdropTemplate")
notesBg:SetPoint("BOTTOMLEFT", 14, 12)
notesBg:SetPoint("BOTTOMRIGHT", -14, 12)
notesBg:SetHeight(48)
notesBg:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
notesBg:SetBackdropColor(0.03, 0.03, 0.03, 0.95)

local notesBox = CreateFrame("EditBox", nil, notesBg)
notesBox:SetMultiLine(true)
notesBox:SetFontObject("ChatFontNormal")
notesBox:SetPoint("TOPLEFT", 8, -6)
notesBox:SetPoint("BOTTOMRIGHT", -8, 6)
notesBox:SetAutoFocus(false)
notesBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
notesBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput and selectedKey and ns.db and ns.db.notes then
        ns.db.notes[selectedKey] = self:GetText()
    end
end)

-- Story Reader ScrollFrame: anchored below entrySummary and above relatedLabel
storyScrollFrame = CreateFrame("ScrollFrame", "ChronicleWeaverStoryScrollFrame", readerPanel, "UIPanelScrollFrameTemplate")
storyScrollFrame:SetPoint("TOPLEFT", entrySummary, "BOTTOMLEFT", 0, -10)
storyScrollFrame:SetPoint("BOTTOMRIGHT", readerPanel, "BOTTOMRIGHT", -28, 124)

local storyScrollChild = CreateFrame("Frame", nil, storyScrollFrame)
storyScrollChild:SetSize(370, 1)
storyScrollFrame:SetScrollChild(storyScrollChild)

storyScrollFrame:SetScript("OnSizeChanged", function(self, width)
    if width and width > 0 then
        storyScrollChild:SetWidth(width)
    end
end)

local entryStory = storyScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
entryStory:SetPoint("TOPLEFT", storyScrollChild, "TOPLEFT", 0, 0)
entryStory:SetPoint("TOPRIGHT", storyScrollChild, "TOPRIGHT", 0, 0)
entryStory:SetJustifyH("LEFT")
entryStory:SetSpacing(3)

-- Unlock / Reveal Button parented to the scroll child
local revealBtn = CreateFrame("Button", nil, storyScrollChild, "UIPanelButtonTemplate")
revealBtn:SetSize(160, 24)
revealBtn:SetPoint("TOPLEFT", entryStory, "BOTTOMLEFT", 0, -12)
revealBtn:SetText("Unlock Entry Manually")
revealBtn:Hide()
revealBtn:SetScript("OnClick", function()
    if selectedKey then
        ns.UnlockEntry(selectedKey)
    end
end)

function ns.SelectEntry(entryKey)
    if not entryKey or not ns.LoreByKey or not ns.LoreByKey[entryKey] then return end
    selectedKey = entryKey
    prevSelectedKey = entryKey
    if storyScrollFrame then
        storyScrollFrame:SetVerticalScroll(0)
    end
    local entry = ns.LoreByKey[entryKey]
    if entry and activeCategory ~= "ALL" and entry.category ~= activeCategory then
        activeCategory = entry.category
    end
    if main:IsShown() and ns.RefreshUI then
        ns.RefreshUI()
    end
end

-- Helper: Faction Matching
local function MatchesFaction(entry, filterFaction)
    if not filterFaction or filterFaction == "ALL" then return true end
    local f = entry.faction
    if not f and ns.db and ns.db.discoveredMeta and ns.db.discoveredMeta[entry.key] then
        f = ns.db.discoveredMeta[entry.key].faction
    end
    -- Entries with no assigned faction or explicitly Neutral show up under Neutral and under factions
    if not f or f == "" or f == "Neutral" then
        return true
    end
    return f:lower() == filterFaction:lower()
end

-- Helper: Character Matching
local function MatchesCharacter(entry, filterScope, currentChar)
    if not filterScope or filterScope == "ALL" then return true end
    if not currentChar or currentChar == "" then return true end

    -- Explicitly harvested or authored by a character
    if entry.character and entry.character ~= "" then
        return entry.character == currentChar
    end

    -- Discovered by a character in discoveredMeta
    local meta = ns.db and ns.db.discoveredMeta and ns.db.discoveredMeta[entry.key]
    if meta and meta.char and meta.char ~= "" then
        return meta.char == currentChar
    end

    -- Undiscovered static lore entries remain visible across characters
    return true
end

-- ==========================================
-- 3. RENDER & REFRESH PIPELINE
-- ==========================================
function ns.RefreshUI()
    if not ns.db or not main:IsShown() then return end

    spoilerBtn:SetText(ns.db.spoilerFree and "Spoilers: Hidden" or "Spoilers: Shown")

    local currentFactionFilter = ns.db.factionFilter or "ALL"
    if currentFactionFilter == "Alliance" then
        factionBtn:SetText("Faction: |cff00aaffAlliance|r")
    elseif currentFactionFilter == "Horde" then
        factionBtn:SetText("Faction: |cffff3b30Horde|r")
    elseif currentFactionFilter == "Neutral" then
        factionBtn:SetText("Faction: |cff4cd964Neutral|r")
    else
        factionBtn:SetText("Faction: All")
    end

    local currentCharFilter = ns.db.charFilter or "ALL"
    local myCharKey = ns.GetPlayerKey and ns.GetPlayerKey() or "Current"
    local myCharShort = myCharKey:match("^([^-]+)") or myCharKey
    if currentCharFilter == "CURRENT" then
        charBtn:SetText("Char: |cffffd100" .. myCharShort .. "|r")
    else
        charBtn:SetText("Chars: All")
    end

    -- Filter entries
    local filtered = {}
    if ns.LoreEntries then
        for _, entry in ipairs(ns.LoreEntries) do
            local catMatch = (activeCategory == "ALL") or (entry.category == activeCategory)
            local queryMatch = (searchQuery == "")
                or (entry.title and entry.title:lower():find(searchQuery, 1, true))
                or (entry.summary and entry.summary:lower():find(searchQuery, 1, true))
            local factionMatch = MatchesFaction(entry, currentFactionFilter)
            local charMatch = MatchesCharacter(entry, currentCharFilter, myCharKey)

            if catMatch and queryMatch and factionMatch and charMatch then
                table.insert(filtered, entry)
            end
        end
    end

    filteredCount = #filtered
    local maxOffset = math.max(0, filteredCount - 21)
    if listScrollOffset > maxOffset then
        listScrollOffset = maxOffset
    end

    if selectedKey and ns.LoreByKey and not ns.LoreByKey[selectedKey] then
        selectedKey = nil
    end

    if not selectedKey and filtered[1] then
        selectedKey = filtered[1].key
        if storyScrollFrame then
            storyScrollFrame:SetVerticalScroll(0)
        end
        prevSelectedKey = selectedKey
    end

    -- Reset vertical scroll to 0 whenever selectedKey changes
    if selectedKey ~= prevSelectedKey then
        prevSelectedKey = selectedKey
        if storyScrollFrame then
            storyScrollFrame:SetVerticalScroll(0)
        end
    end

    -- Update visual scrollbar
    if listScrollBar then
        isUpdatingScrollBar = true
        listScrollBar:SetMinMaxValues(0, maxOffset)
        listScrollBar:SetValue(listScrollOffset)
        if maxOffset == 0 then
            listScrollBar:Hide()
        else
            listScrollBar:Show()
        end
        isUpdatingScrollBar = false
    end

    -- Render left-side list buttons (up to 21 rows of 22px height with listScrollOffset)
    local categoryShortTags = {
        Book = "|cff4cd964[B]|r",
        Quest = "|cff4cd964[Q]|r",
        Zone = "|cff4cd964[Z]|r",
        Dungeon = "|cff4cd964[D]|r",
        NPC = "|cffffd100[N]|r",
        Relic = "|cff4cd964[R]|r",
        Deduction = "|cffc586c0[!]|r",
    }
    local lockedShortTags = {
        Book = "[B]",
        Quest = "[Q]",
        Zone = "[Z]",
        Dungeon = "[D]",
        NPC = "[N]",
        Relic = "[R]",
        Deduction = "[!]",
    }

    for i = 1, 21 do
        local btn = listButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, listPanel)
            btn:SetSize(246, 20)
            btn:SetPoint("TOPLEFT", 8, -6 - (i - 1) * 22)

            btn.sel = btn:CreateTexture(nil, "BACKGROUND")
            btn.sel:SetAllPoints()
            btn.sel:SetColorTexture(0.83, 0.66, 0.35, 0.28)
            btn.sel:Hide()

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(0.83, 0.66, 0.35, 0.18)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", 6, 0)
            btn.text:SetPoint("RIGHT", -6, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetWordWrap(false)
            btn.text:SetNonSpaceWrap(false)
            if btn.text.SetMaxLines then btn.text:SetMaxLines(1) end
            btn.text:SetHeight(16)

            -- Enable mouse-wheel scrolling over list items as well
            btn:EnableMouseWheel(true)
            btn:SetScript("OnMouseWheel", function(_, delta)
                ScrollEntryList(delta)
            end)

            listButtons[i] = btn
        end

        btn:SetSize(246, 20)
        btn.text:SetWordWrap(false)
        btn.text:SetNonSpaceWrap(false)
        if btn.text.SetMaxLines then btn.text:SetMaxLines(1) end
        btn.text:SetHeight(16)
        btn:SetScript("OnMouseWheel", function(_, delta)
            ScrollEntryList(delta)
        end)

        local itemIndex = listScrollOffset + i
        local item = filtered[itemIndex]
        if item then
            local isSelected = (selectedKey == item.key)
            local unlocked = ns.db.discovered and (ns.db.discovered[item.key] ~= nil)
            local prefix
            if unlocked then
                prefix = (categoryShortTags[item.category] or "|cff4cd964[ ]|r") .. " "
            else
                prefix = "|cff777777" .. (lockedShortTags[item.category] or "[]") .. "|r "
            end

            if isSelected then
                btn.text:SetText(prefix .. "|cffffd100" .. (item.title or "Unknown") .. "|r")
            elseif unlocked then
                btn.text:SetText(prefix .. "|cffffffff" .. (item.title or "Unknown") .. "|r")
            else
                btn.text:SetText(prefix .. "|cff888888" .. (item.title or "Unknown") .. "|r")
            end

            if isSelected then
                btn.sel:Show()
            else
                btn.sel:Hide()
            end

            btn:SetScript("OnClick", function()
                if selectedKey ~= item.key then
                    selectedKey = item.key
                    if storyScrollFrame then
                        storyScrollFrame:SetVerticalScroll(0)
                    end
                    prevSelectedKey = selectedKey
                    ns.RefreshUI()
                end
            end)
            btn:Show()
        else
            btn.sel:Hide()
            btn:Hide()
        end
    end

    -- Scroll indicator label when filtered > 21
    if filteredCount > 21 then
        local startIdx = listScrollOffset + 1
        local endIdx = math.min(filteredCount, listScrollOffset + 21)
        listScrollIndicator:SetText(string.format("Showing %d-%d of %d", startIdx, endIdx, filteredCount))
        listScrollIndicator:Show()
    else
        listScrollIndicator:Hide()
    end

    -- Render selected entry details
    local entry = selectedKey and ns.LoreByKey and ns.LoreByKey[selectedKey]
    if not entry then
        entryHeading:SetText("No Lore Entry Selected")
        entryMeta:SetText("")
        entrySummary:SetText("")
        entryStory:SetText("")
        revealBtn:Hide()
        pinBtn:Hide()
        deleteBtn:Hide()
        notesBox:SetText("")
        storyScrollChild:SetHeight(1)
        relatedLabel:Hide()
        for i = 1, 4 do
            relatedButtons[i]:Hide()
        end
        return
    end

    local isUnlocked = ns.db.discovered and (ns.db.discovered[entry.key] ~= nil)
    local isDeduction = (entry.category == "Deduction")
    entryHeading:SetText(entry.title or "Unknown")
    entrySummary:SetText(entry.summary or "")

    -- Show "Pin to Map" button if this entry has valid map coordinates
    local hasCoords = (entry.mapID and entry.x and entry.x > 0)
    if hasCoords then
        pinBtn:Show()
    else
        pinBtn:Hide()
    end

    -- Show "Delete" button when entry is a harvested Book, Quest, or Relic
    local isHarvested = (entry.category == "Book")
        or (entry.category == "Quest")
        or (ns.db.books and ns.db.books[entry.key])
        or (ns.db.quests and ns.db.quests[entry.key])
        or (ns.db.items and ns.db.items[entry.key])
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

    local effFaction = entry.faction
    if not effFaction and ns.db.discoveredMeta and ns.db.discoveredMeta[entry.key] then
        effFaction = ns.db.discoveredMeta[entry.key].faction
    end
    local factionBadge = ""
    if effFaction == "Alliance" then
        factionBadge = "     |cff00aaff[Alliance]|r"
    elseif effFaction == "Horde" then
        factionBadge = "     |cffff3b30[Horde]|r"
    elseif effFaction == "Neutral" then
        factionBadge = "     |cff4cd964[Neutral]|r"
    end

    local effChar = entry.character
    if not effChar and ns.db.discoveredMeta and ns.db.discoveredMeta[entry.key] then
        effChar = ns.db.discoveredMeta[entry.key].char
    end
    local charBadge = ""
    if effChar and effChar ~= "" then
        local shortChar = effChar:match("^([^-]+)") or effChar
        charBadge = string.format(" (|cffffd100%s|r)", shortChar)
    end

    if isDeduction and not isUnlocked and entry.requiredClues then
        -- Locked Deduction: Clue synthesis checklist (Step 3.1)
        local gathered = 0
        local total = #entry.requiredClues
        local clueLines = {}

        for _, clueKey in ipairs(entry.requiredClues) do
            local found = ns.db.discovered and (ns.db.discovered[clueKey] ~= nil)
            local clueEntry = ns.LoreByKey and ns.LoreByKey[clueKey]
            local clueTitle = clueEntry and clueEntry.title or clueKey
            local clueCat = clueEntry and clueEntry.category or "Lore"

            if found then
                gathered = gathered + 1
                table.insert(clueLines, string.format("  |cff4cd964[+]|r |cffffd100%s|r (|cffaaaaaa%s|r)", clueTitle, clueCat))
            else
                table.insert(clueLines, string.format("  |cff777777[]|r |cff888888%s (Undiscovered)|r", clueTitle))
            end
        end

        entryMeta:SetText(string.format("%s     %s%s     |cffc586c0Locked Deduction (Clues Gathered: %d / %d)|r",
            entry.category,
            entry.era or "Synthesis",
            factionBadge,
            gathered,
            total
        ))

        local checklistText = string.format(
            "|cffc586c0[Clue Synthesis Required]|r\n" ..
            "Discover the following prerequisite lore across Azeroth to synthesize this deduction:\n\n" ..
            "|cffd4a85aClues Gathered: %d / %d|r\n%s\n\n" ..
            "|cff888888[Once all clues are gathered, this deduction will automatically synthesize and unlock in your journal.]|r",
            gathered, total, table.concat(clueLines, "\n")
        )

        entryStory:SetText(checklistText)
        revealBtn:SetText("Unlock Deduction Manually")
        revealBtn:Show()
        local textHeight = entryStory:GetStringHeight() or 0
        storyScrollChild:SetHeight(math.max(1, textHeight + 12 + 24 + 10))
    else
        entryMeta:SetText(string.format("%s     %s%s     %s%s",
            entry.category or "Lore",
            entry.era or "Unknown",
            factionBadge,
            isUnlocked and (isDeduction and "|cffc586c0Synthesized|r" or "|cff4cd964Discovered|r") or "|cffff9500Undiscovered|r",
            isUnlocked and charBadge or ""
        ))

        if isUnlocked or not ns.db.spoilerFree then
            entryStory:SetText(entry.story or "")
            revealBtn:Hide()
            local textHeight = entryStory:GetStringHeight() or 0
            storyScrollChild:SetHeight(math.max(1, textHeight + 10))
        else
            entryStory:SetText("|cff888888[Spoiler-Safe Mode Active: Visit this location or target this character in Azeroth to unlock the full story or click below to reveal it now.]|r")
            revealBtn:SetText("Unlock Entry Manually")
            revealBtn:Show()
            local textHeight = entryStory:GetStringHeight() or 0
            storyScrollChild:SetHeight(math.max(1, textHeight + 12 + 24 + 10))
        end
    end

    -- Render Connected Lore jump-chips (Step 2.2)
    local validRelated = {}
    if entry.related and type(entry.related) == "table" and ns.LoreByKey then
        for _, relKey in ipairs(entry.related) do
            local relEntry = ns.LoreByKey[relKey]
            if relEntry then
                table.insert(validRelated, { key = relKey, entry = relEntry })
                if #validRelated >= 4 then
                    break
                end
            end
        end
    end

    if #validRelated > 0 then
        relatedLabel:Show()
        for i = 1, 4 do
            local chip = relatedButtons[i]
            local relData = validRelated[i]
            if relData then
                local relEntry = relData.entry
                local isRelUnlocked = ns.db.discovered and (ns.db.discovered[relData.key] ~= nil)
                local colorCode = isRelUnlocked and "|cff4cd964" or "|cffaaaaaa"
                local rawTitle = relEntry.title or "Unknown"
                local displayTitle = rawTitle
                if #displayTitle > 18 then
                    displayTitle = displayTitle:sub(1, 16) .. ".."
                end
                chip:SetText(colorCode .. displayTitle .. "|r")
                chip:SetScript("OnClick", function()
                    selectedKey = relData.key
                    if storyScrollFrame then
                        storyScrollFrame:SetVerticalScroll(0)
                    end
                    prevSelectedKey = selectedKey
                    ns.RefreshUI()
                end)
                chip:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:SetText(rawTitle, 1, 0.82, 0.45)
                    local status = isRelUnlocked and "|cff4cd964Discovered|r" or "|cffaaaaaaUndiscovered|r"
                    GameTooltip:AddLine(string.format("%s (%s)", relEntry.category or "Lore", status), 0.8, 0.8, 0.8)
                    GameTooltip:AddLine("Click to view related chronicle entry.", 0.6, 0.6, 0.6)
                    GameTooltip:Show()
                end)
                chip:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
                chip:Show()
            else
                chip:Hide()
            end
        end
    else
        relatedLabel:Hide()
        for i = 1, 4 do
            relatedButtons[i]:Hide()
        end
    end

    notesBox:SetText((ns.db.notes and ns.db.notes[entry.key]) or "")
end

function ns.ToggleMainFrame(forceOpen)
    if ns.ScanQuestLog then
        ns.ScanQuestLog()
    end
    if forceOpen then
        if not main:IsShown() and ns.RestoreWindowPosition then
            ns.RestoreWindowPosition()
        end
        main:Show()
    else
        if not main:IsShown() then
            if ns.RestoreWindowPosition then
                ns.RestoreWindowPosition()
            end
            main:Show()
        else
            main:Hide()
        end
    end
    if main:IsShown() then
        ns.RefreshUI()
    end
end
