-- =========================================================================
-- UI/MainFrame.lua
-- 980x660 resizable window shell, sleek journal tabs & dark-bronze controls.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

ns.activeCategory = "Zone"
ns.searchQuery = ""

-- -------------------------------------------------------------------------
-- Main Window Frame
-- -------------------------------------------------------------------------
local main = CreateFrame("Frame", "ChronicleWeaverMainFrame", UIParent, "BackdropTemplate")
main:SetSize(980, 660)
main:SetPoint("CENTER")
main:SetMovable(true)
main:SetResizable(true)
if main.SetResizeBounds then
    main:SetResizeBounds(780, 500, 1400, 950)
elseif main.SetMinResize then
    main:SetMinResize(780, 500)
    main:SetMaxResize(1400, 950)
end
main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:Hide()
tinsert(UISpecialFrames, "ChronicleWeaverMainFrame")

-- Dragging & Position Saving
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

-- Live OnSizeChanged Dynamic Reflow Handler
main:SetScript("OnSizeChanged", function(self, width, height)
    if not width or width <= 0 or not height or height <= 0 then return end
    if main.listPanel then
        local targetWidth = math.floor(math.min(360, math.max(260, width * 0.28)))
        if main.listPanel:GetWidth() ~= targetWidth then
            main.listPanel:SetWidth(targetWidth)
        end
    end
    if ns.RefreshUI and self:IsShown() then
        ns.RefreshUI()
    end
end)

-- Bottom-Right Resize Grip Button
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

-- Header Logo Emblem & Title
local headerLogo = main:CreateTexture(nil, "ARTWORK")
headerLogo:SetSize(26, 26)
headerLogo:SetPoint("TOPLEFT", 16, -11)
headerLogo:SetTexture(ns.MediaPath .. "logo")
main.headerLogo = headerLogo

local titleText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("LEFT", headerLogo, "RIGHT", 8, 0)
titleText:SetText("|cffd4a85aChronicleWeaver|r - WoW: Forever Lore Codex")
main.titleText = titleText

-- Top Header Counter (Discovered: X or Discovered: X / Y)
local statsText = main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statsText:SetPoint("LEFT", titleText, "RIGHT", 14, 0)
statsText:SetTextColor(0.85, 0.72, 0.45)
main.statsText = statsText

-- Close Button
local closeBtn = CreateFrame("Button", nil, main, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -6, -6)

-- -------------------------------------------------------------------------
-- Helper: Sleek Dark-Bronze Journal Utility Button
-- -------------------------------------------------------------------------
local function CreateJournalUtilityButton(parent, width, height, defaultText)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.12, 0.10, 0.09, 0.95)
    btn:SetBackdropBorderColor(0.40, 0.32, 0.20, 1.0)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.85, 0.68, 0.35, 0.18)

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetTextColor(0.90, 0.82, 0.70)
    fs:SetText(defaultText or "")
    btn.text = fs
    btn.SetText = function(self, t) self.text:SetText(t) end
    btn.GetText = function(self) return self.text:GetText() end

    btn:HookScript("OnEnter", function(self)
        self:SetBackdropColor(0.20, 0.16, 0.12, 1.0)
        self:SetBackdropBorderColor(0.75, 0.60, 0.30, 1.0)
        self.text:SetTextColor(1.0, 0.95, 0.85)
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.10, 0.09, 0.95)
        self:SetBackdropBorderColor(0.40, 0.32, 0.20, 1.0)
        self.text:SetTextColor(0.90, 0.82, 0.70)
    end)

    return btn
end

-- -------------------------------------------------------------------------
-- Header Action Buttons (Theme, Spoilers, Faction, Grouping)
-- -------------------------------------------------------------------------
-- Theme Toggle Button ("Theme: Parchment/Dark")
local themeBtn = CreateJournalUtilityButton(main, 125, 22, "Theme: Parchment")
themeBtn:SetPoint("TOPRIGHT", -38, -14)
themeBtn:SetScript("OnClick", function()
    if ns.db then
        ns.db.theme = (ns.db.theme == "DARK") and "PARCHMENT" or "DARK"
        if ns.ApplyTheme then ns.ApplyTheme() end
        if ns.RefreshUI then ns.RefreshUI() end
    end
end)
themeBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Dual-Theme Engine", 1, 0.82, 0.45)
    GameTooltip:AddLine("Toggle between Royal Archivist Parchment and Midnight Obsidian.", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end)
themeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
main.themeBtn = themeBtn

-- Spoiler Protection Button ("Spoilers: Hidden/Shown")
local spoilerBtn = CreateJournalUtilityButton(main, 110, 22, "Spoilers: Hidden")
spoilerBtn:SetPoint("RIGHT", themeBtn, "LEFT", -6, 0)
spoilerBtn:SetScript("OnClick", function()
    if ns.db then
        ns.db.spoilerFree = not ns.db.spoilerFree
        if ns.RefreshUI then ns.RefreshUI() end
    end
end)
spoilerBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Spoiler Protection", 1, 0.82, 0.45)
    GameTooltip:AddLine("When enabled, undiscovered lore details stay shrouded in mystery.", 0.9, 0.9, 0.9)
    GameTooltip:Show()
end)
spoilerBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
main.spoilerBtn = spoilerBtn

-- Faction Filter Button
local factionBtn = CreateJournalUtilityButton(main, 95, 22, "Faction: All")
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
    if ns.ResetListOffset then ns.ResetListOffset() end
    if ns.RefreshUI then ns.RefreshUI() end
end)
factionBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Faction Filter", 1, 0.82, 0.45)
    GameTooltip:AddLine("Left-Click: Cycle All -> Alliance -> Horde -> Neutral", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("Right-Click: Reset filter to All", 0.65, 0.65, 0.65)
    GameTooltip:Show()
end)
factionBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
main.factionBtn = factionBtn

-- Grouping Mode Cycle Button ("Group: Zone/Era/Flat")
local groupBtn = CreateJournalUtilityButton(main, 96, 22, "Group: Zone")
groupBtn:SetPoint("RIGHT", factionBtn, "LEFT", -6, 0)
groupBtn:SetScript("OnClick", function()
    if not ns.db then return end
    local cur = ns.db.groupMode or "ZONE"
    if cur == "ZONE" then
        ns.db.groupMode = "ERA"
    elseif cur == "ERA" then
        ns.db.groupMode = "NONE"
    else
        ns.db.groupMode = "ZONE"
    end
    if ns.ResetListOffset then ns.ResetListOffset() end
    if ns.RefreshUI then ns.RefreshUI() end
end)
groupBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Sidebar Grouping Mode", 1, 0.82, 0.45)
    GameTooltip:AddLine("Left-Click: Cycle Zone Folders -> Chronological Era -> Flat List", 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
groupBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
main.groupBtn = groupBtn

-- Scope Toggle Button ("Scope: Account" vs. "Scope: Char")
local charBtn = CreateJournalUtilityButton(main, 108, 22, "Scope: Account")
charBtn:SetPoint("RIGHT", groupBtn, "LEFT", -6, 0)
charBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
charBtn:SetScript("OnClick", function(_, button)
    if not ns.db then return end
    if button == "RightButton" then
        ns.db.charFilter = "ALL"
    else
        local cur = ns.db.charFilter or "ALL"
        ns.db.charFilter = (cur == "CURRENT") and "ALL" or "CURRENT"
    end
    if ns.ResetListOffset then ns.ResetListOffset() end
    if ns.RefreshUI then ns.RefreshUI() end
end)
charBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Character vs. Account Scope", 1, 0.82, 0.45)
    GameTooltip:AddLine("Left-Click: Toggle between Account-Wide and Current Character (" .. (ns.GetPlayerKey and ns.GetPlayerKey() or "Player") .. ")", 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine("Right-Click: Reset to Account-Wide", 0.65, 0.65, 0.65)
    GameTooltip:Show()
end)
charBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
main.charBtn = charBtn

-- -------------------------------------------------------------------------
-- Category Navigation Bar (7 Strict Category Tabs)
-- -------------------------------------------------------------------------
local categories = { "Zone", "Dungeon", "NPC", "Relic", "Book", "Quest", "Dossier" }
local catWidths = {
    Zone = 58,
    Dungeon = 70,
    NPC = 52,
    Relic = 58,
    Book = 58,
    Quest = 60,
    Dossier = 66,
}

local catIcons = {
    Zone    = "Interface\\Icons\\INV_Misc_Map_01",
    Dungeon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    NPC     = "Interface\\Icons\\INV_Misc_Head_Human_01",
    Relic   = "Interface\\Icons\\INV_Misc_Gem_Variety_01",
    Book    = "Interface\\Icons\\INV_Misc_Book_09",
    Quest   = "Interface\\Icons\\INV_Misc_Note_01",
    Dossier = "Interface\\Icons\\INV_Misc_Spyglass_02",
}

local catButtons = {}
local startX = 14
for _, cat in ipairs(categories) do
    local width = catWidths[cat] or 58
    local btn = CreateFrame("Button", nil, main, "BackdropTemplate")
    btn:SetSize(width, 24)
    btn:SetPoint("TOPLEFT", startX, -46)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn.category = cat

    -- 12x12 Tab Category Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(12, 12)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetTexture(catIcons[cat] or "Interface\\Icons\\INV_Misc_Book_09")
    btn.icon = icon

    -- Tab Label
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    text:SetPoint("RIGHT", -3, 0)
    text:SetJustifyH("CENTER")
    text:SetText(cat)
    btn.text = text

    -- Glowing Gold Bottom Highlight Bar (active state)
    local glowBar = btn:CreateTexture(nil, "OVERLAY")
    glowBar:SetPoint("BOTTOMLEFT", 2, 1)
    glowBar:SetPoint("BOTTOMRIGHT", -2, 1)
    glowBar:SetHeight(2)
    glowBar:SetColorTexture(0.95, 0.80, 0.35, 1.0)
    glowBar:Hide()
    btn.glowBar = glowBar

    -- Hover Highlight
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.85, 0.68, 0.35, 0.16)

    btn:SetScript("OnClick", function()
        ns.activeCategory = cat
        if ns.ResetListOffset then ns.ResetListOffset() end
        if ns.RefreshUI then ns.RefreshUI() end
    end)

    catButtons[cat] = btn
    startX = startX + width + 3
end
main.catButtons = catButtons

-- Options Button (Top-Right of Tab Row)
local optionsBtn = CreateJournalUtilityButton(main, 64, 24, "Options")
optionsBtn:SetPoint("TOPRIGHT", -16, -46)
optionsBtn:SetScript("OnClick", function()
    if ns.ToggleOptionsPanel then
        ns.ToggleOptionsPanel()
    end
end)
optionsBtn:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("General Options", 1, 0.82, 0.45)
    GameTooltip:AddLine("Configure automatic tracking (quests, books, relics, world), tooltips, radar, and sounds.", 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
optionsBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
main.optionsBtn = optionsBtn

-- Library Ledger & Export Button
local ledgerBtn = CreateJournalUtilityButton(main, 58, 24, "Ledger")
ledgerBtn:SetPoint("RIGHT", optionsBtn, "LEFT", -5, 0)
ledgerBtn:SetScript("OnClick", function()
    if ns.ToggleLedgerPanel then
        ns.ToggleLedgerPanel()
    end
end)
ledgerBtn:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Library Books Ledger & Export", 1, 0.82, 0.45)
    GameTooltip:AddLine("Track all 35 WoW: Forever Library Books, pin missing spawns, or export chronicles to Markdown/Lua.", 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end)
ledgerBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
main.ledgerBtn = ledgerBtn

-- Live Search Box (Sleek Dark Obsidian Input)
local searchBox = CreateFrame("EditBox", nil, main, "BackdropTemplate")
searchBox:SetSize(96, 24)
searchBox:SetPoint("RIGHT", ledgerBtn, "LEFT", -5, 0)
searchBox:SetAutoFocus(false)
searchBox:SetFontObject("GameFontHighlightSmall")
searchBox:SetTextInsets(8, 8, 0, 0)
searchBox:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
searchBox:SetBackdropColor(0.08, 0.07, 0.06, 0.95)
searchBox:SetBackdropBorderColor(0.40, 0.32, 0.20, 1.0)
searchBox:SetScript("OnTextChanged", function(self)
    ns.searchQuery = (self:GetText() or ""):lower():match("^%s*(.-)%s*$")
    if ns.ResetListOffset then ns.ResetListOffset() end
    if ns.RefreshUI then ns.RefreshUI() end
end)
searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
main.searchBox = searchBox

local searchLabel = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("RIGHT", searchBox, "LEFT", -6, 0)
searchLabel:SetText("Search:")

-- -------------------------------------------------------------------------
-- Main Content Panels (List Panel on Left, Reader Panel on Right)
-- -------------------------------------------------------------------------
local listPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
listPanel:SetPoint("TOPLEFT", 16, -76)
listPanel:SetPoint("BOTTOMLEFT", 16, 16)
listPanel:SetWidth(270)
main.listPanel = listPanel

local readerPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
readerPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 10, 0)
readerPanel:SetPoint("BOTTOMRIGHT", -16, 16)
main.readerPanel = readerPanel

-- -------------------------------------------------------------------------
-- General Options Overlay Panel
-- -------------------------------------------------------------------------
local optionsPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
optionsPanel:SetSize(580, 460)
optionsPanel:SetPoint("CENTER", main, "CENTER", 0, 0)
optionsPanel:SetFrameLevel(main:GetFrameLevel() + 30)
optionsPanel:EnableMouse(true)
optionsPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 18,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
optionsPanel:SetBackdropColor(0.07, 0.06, 0.05, 0.98)
optionsPanel:SetBackdropBorderColor(0.75, 0.60, 0.25, 1.0)
optionsPanel:Hide()
main.optionsPanel = optionsPanel

local optCloseBtn = CreateFrame("Button", nil, optionsPanel, "UIPanelCloseButton")
optCloseBtn:SetPoint("TOPRIGHT", -6, -6)

local optTitle = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
optTitle:SetPoint("TOPLEFT", 20, -16)
optTitle:SetText("|cffd4a85aChronicleWeaver|r - General Options")

local optSubtitle = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
optSubtitle:SetPoint("TOPLEFT", optTitle, "BOTTOMLEFT", 0, -4)
optSubtitle:SetTextColor(0.75, 0.70, 0.60)
optSubtitle:SetText("Configure automatic lore harvesters, radar, map overlay, tooltips, and soundscapes.")

local optDividerTop = optionsPanel:CreateTexture(nil, "BORDER")
optDividerTop:SetPoint("TOPLEFT", 18, -54)
optDividerTop:SetPoint("TOPRIGHT", -18, -54)
optDividerTop:SetHeight(1)
optDividerTop:SetColorTexture(0.70, 0.55, 0.20, 0.45)

local leftColHeader = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
leftColHeader:SetPoint("TOPLEFT", 22, -64)
leftColHeader:SetTextColor(0.95, 0.80, 0.42)
leftColHeader:SetText("Harvesting, Radar & Map")

local rightColHeader = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rightColHeader:SetPoint("TOPLEFT", 300, -64)
rightColHeader:SetTextColor(0.95, 0.80, 0.42)
rightColHeader:SetText("Interface, Tooltips & Sync")

local optionCheckboxes = {}

local function SetCheckboxVisual(cb, isChecked)
    cb:SetChecked(isChecked)
    if isChecked then
        cb.box:SetBackdropColor(0.18, 0.14, 0.09, 1.0)
        cb.box:SetBackdropBorderColor(0.85, 0.70, 0.35, 1.0)
        cb.check:Show()
        cb.label:SetTextColor(0.95, 0.90, 0.80)
    else
        cb.box:SetBackdropColor(0.08, 0.07, 0.06, 0.95)
        cb.box:SetBackdropBorderColor(0.40, 0.32, 0.20, 1.0)
        cb.check:Hide()
        cb.label:SetTextColor(0.65, 0.60, 0.52)
    end
end

local function CreateOptionCheckbox(parent, optDef, xPos, yPos)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(256, 24)
    cb:SetPoint("TOPLEFT", xPos, yPos)
    cb.optionKey = optDef.key
    cb.defaultVal = (optDef.default ~= false)

    local hl = cb:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.85, 0.68, 0.35, 0.10)

    local box = CreateFrame("Frame", nil, cb, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 2, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    cb.box = box

    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetSize(16, 16)
    check:SetPoint("CENTER", 0, 0)
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetVertexColor(0.95, 0.82, 0.35, 1.0)
    cb.check = check

    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetPoint("RIGHT", -2, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(optDef.label)
    cb.label = label

    cb:SetScript("OnClick", function(self)
        if not ns.db then return end
        local isChecked = self:GetChecked() and true or false
        ns.db[self.optionKey] = isChecked
        SetCheckboxVisual(self, isChecked)
        if optDef.onChange then
            optDef.onChange(isChecked)
        end
    end)

    cb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(optDef.label, 1, 0.82, 0.45)
        GameTooltip:AddLine(optDef.tooltip, 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)

    table.insert(optionCheckboxes, cb)
    return cb
end

local LEFT_OPTIONS = {
    {
        key = "trackQuests",
        label = "Track & Harvest Quests",
        tooltip = "Automatically harvest quest descriptions, narrative objectives, and completion resolutions as you accept and turn in quests.",
    },
    {
        key = "trackBooks",
        label = "Track & Harvest Books & Plaques",
        tooltip = "Automatically archive multi-page books, scrolls, monuments, and lore plaques when opened.",
    },
    {
        key = "trackRelics",
        label = "Track & Harvest Relics & Library Books",
        tooltip = "Automatically harvest quoted flavor-text relics and WoW: Forever Library Books from bags and tooltips.",
    },
    {
        key = "trackWorld",
        label = "Track Zones & Target NPCs",
        tooltip = "Automatically discover curated zones, subzones, and notable NPCs as you explore Azeroth.",
    },
    {
        key = "showGossipButton",
        label = "Show '[+] Archive Lore' on Gossip",
        tooltip = "Display the 1-click '[+] Archive Lore' button on NPC gossip windows.",
        onChange = function()
            if ns.UpdateGossipButtonVisibility then
                ns.UpdateGossipButtonVisibility()
            end
        end,
    },
    {
        key = "proximityRadar",
        label = "Archivist's Whisper Proximity Radar",
        tooltip = "Alert you when approaching an uncollected Library Book or undiscovered chronicle nearby.",
    },
    {
        key = "showMapOverlay",
        label = "Show Progress Bar on World Map",
        tooltip = "Display a ChronicleWeaver zone progress bar and Pin Missing button at the bottom of the World Map.",
        onChange = function()
            if ns.UpdateWorldMapOverlay then
                ns.UpdateWorldMapOverlay()
            end
        end,
    },
}

local RIGHT_OPTIONS = {
    {
        key = "spoilerFree",
        label = "Spoiler-Safe Mode",
        tooltip = "Keep undiscovered lore entries and synthesis deductions hidden until uncovered in Azeroth.",
        onChange = function()
            if ns.RefreshUI then
                ns.RefreshUI()
            end
        end,
    },
    {
        key = "autoToast",
        label = "Show Discovery Toast Banners",
        tooltip = "Display a fanfare toast banner whenever a new lore entry is discovered.",
    },
    {
        key = "toastSound",
        label = "Play Discovery Sound Effects",
        tooltip = "Play an audio effect when Discovery or Compass Whisper toast banners appear.",
    },
    {
        key = "toastLocked",
        label = "Lock Discovery Toast Position",
        default = false,
        tooltip = "Prevent dragging the Discovery Toast banner across the screen.",
    },
    {
        key = "chatAlerts",
        label = "Print Harvest Alerts in Chat",
        tooltip = "Print chat notifications when books, quests, relics, or delivery hints are harvested.",
    },
    {
        key = "showTooltips",
        label = "Show Lore on Tooltips",
        tooltip = "Append ChronicleWeaver lore summaries to NPC and item tooltips.",
    },
    {
        key = "showDeliveryHints",
        label = "Show Library Book Delivery Hints",
        tooltip = "Display faction librarian turn-in NPCs, coordinates, and reward notes on deliverable lore books.",
    },
    {
        key = "addonSync",
        label = "Party/Guild Addon Comms Sync",
        tooltip = "Allow sharing and receiving chronicle links with group and guild members over CW_LORE.",
    },
}

for idx, optDef in ipairs(LEFT_OPTIONS) do
    CreateOptionCheckbox(optionsPanel, optDef, 22, -88 - (idx - 1) * 30)
end
for idx, optDef in ipairs(RIGHT_OPTIONS) do
    CreateOptionCheckbox(optionsPanel, optDef, 300, -88 - (idx - 1) * 30)
end

-- Middle Quick-Mode Row (Era Filter, Soundscape, Open Ledger)
local eraCycleBtn = CreateJournalUtilityButton(optionsPanel, 166, 22, "Era Filter: All")
eraCycleBtn:SetPoint("BOTTOMLEFT", 20, 74)
eraCycleBtn:SetScript("OnClick", function()
    if not ns.db then return end
    local cur = ns.db.eraFilter or "ALL"
    if cur == "ALL" then
        ns.db.eraFilter = "FOREVER"
    elseif cur == "FOREVER" then
        ns.db.eraFilter = "CLASSIC"
    elseif cur == "CLASSIC" then
        ns.db.eraFilter = "HARVEST"
    else
        ns.db.eraFilter = "ALL"
    end
    if ns.ResetListOffset then ns.ResetListOffset() end
    if ns.RefreshUI then ns.RefreshUI() end
    if ns.RefreshOptionsPanel then ns.RefreshOptionsPanel() end
end)

local soundCycleBtn = CreateJournalUtilityButton(optionsPanel, 166, 22, "Sound: Chime")
soundCycleBtn:SetPoint("LEFT", eraCycleBtn, "RIGHT", 10, 0)
soundCycleBtn:SetScript("OnClick", function()
    if not ns.db then return end
    local cur = ns.db.soundStyle or "CHIME"
    if cur == "CHIME" then
        ns.db.soundStyle = "PAGETURN"
    elseif cur == "PAGETURN" then
        ns.db.soundStyle = "FANFARE"
    elseif cur == "FANFARE" then
        ns.db.soundStyle = "MUTE"
    else
        ns.db.soundStyle = "CHIME"
    end
    if ns.RefreshOptionsPanel then ns.RefreshOptionsPanel() end
    if ns.PlayChronicleSound then ns.PlayChronicleSound() end
end)

local openLedgerBtn = CreateJournalUtilityButton(optionsPanel, 188, 22, "Library Ledger & Export")
openLedgerBtn:SetPoint("LEFT", soundCycleBtn, "RIGHT", 10, 0)
openLedgerBtn:SetScript("OnClick", function()
    optionsPanel:Hide()
    if ns.ToggleLedgerPanel then
        ns.ToggleLedgerPanel("LEDGER")
    end
end)

local optDividerBot = optionsPanel:CreateTexture(nil, "BORDER")
optDividerBot:SetPoint("BOTTOMLEFT", 18, 60)
optDividerBot:SetPoint("BOTTOMRIGHT", -18, 60)
optDividerBot:SetHeight(1)
optDividerBot:SetColorTexture(0.70, 0.55, 0.20, 0.45)

local scanQuestsBtn = CreateJournalUtilityButton(optionsPanel, 148, 24, "Scan Active Quest Log")
scanQuestsBtn:SetPoint("BOTTOMLEFT", 20, 20)
scanQuestsBtn:SetScript("OnClick", function()
    if ns.ScanActiveQuestLog then
        ns.ScanActiveQuestLog(true)
        ns.Print("Scanned your active Quest Log for chronicles.")
        if ns.RefreshUI then ns.RefreshUI() end
    end
end)

local optThemeBtn = CreateJournalUtilityButton(optionsPanel, 102, 24, "Toggle Theme")
optThemeBtn:SetPoint("LEFT", scanQuestsBtn, "RIGHT", 8, 0)
optThemeBtn:SetScript("OnClick", function()
    if ns.db then
        ns.db.theme = (ns.db.theme == "DARK") and "PARCHMENT" or "DARK"
        if ns.ApplyTheme then ns.ApplyTheme() end
        if ns.RefreshUI then ns.RefreshUI() end
    end
end)

local resetSizeBtn = CreateJournalUtilityButton(optionsPanel, 126, 24, "Reset Window")
resetSizeBtn:SetPoint("LEFT", optThemeBtn, "RIGHT", 8, 0)
resetSizeBtn:SetScript("OnClick", function()
    if InCombatLockdown() then
        ns.Print("Cannot resize window during combat.")
        return
    end
    main:ClearAllPoints()
    main:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    main:SetSize(980, 660)
    if main.listPanel then
        main.listPanel:SetWidth(270)
    end
    if ns.db then
        ns.db.windowPos = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0, width = 980, height = 660 }
    end
    if ns.ResetToastPosition then
        ns.ResetToastPosition()
    end
    if ns.RefreshUI then ns.RefreshUI() end
    ns.Print("Window and toast positions reset to defaults.")
end)

local optDoneBtn = CreateJournalUtilityButton(optionsPanel, 82, 24, "Close")
optDoneBtn:SetPoint("BOTTOMRIGHT", -20, 20)
optDoneBtn:SetScript("OnClick", function()
    optionsPanel:Hide()
end)

function ns.RefreshOptionsPanel()
    if not optionsPanel or not ns.db then return end
    for _, cb in ipairs(optionCheckboxes) do
        local val = ns.db[cb.optionKey]
        if val == nil then
            val = cb.defaultVal
        end
        SetCheckboxVisual(cb, val == true)
    end

    local era = ns.db.eraFilter or "ALL"
    local eraLabel = "Era Filter: All"
    if era == "FOREVER" then
        eraLabel = "Era: |cffd4a85aForever+|r"
    elseif era == "CLASSIC" then
        eraLabel = "Era: |cff58a6ffClassic|r"
    elseif era == "HARVEST" then
        eraLabel = "Era: |cff4cd964Harvested|r"
    end
    eraCycleBtn:SetText(eraLabel)

    local sStyle = ns.db.soundStyle or "CHIME"
    local sLabel = "Sound: Chime"
    if sStyle == "PAGETURN" then
        sLabel = "Sound: Page Turn"
    elseif sStyle == "FANFARE" then
        sLabel = "Sound: Fanfare"
    elseif sStyle == "MUTE" then
        sLabel = "Sound: Muted"
    end
    soundCycleBtn:SetText(sLabel)
end

-- -------------------------------------------------------------------------
-- Library Books Ledger & Lore Export Overlay Panel
-- -------------------------------------------------------------------------
local ledgerPanel = CreateFrame("Frame", nil, main, "BackdropTemplate")
ledgerPanel:SetSize(660, 450)
ledgerPanel:SetPoint("CENTER", main, "CENTER", 0, 0)
ledgerPanel:SetFrameLevel(main:GetFrameLevel() + 32)
ledgerPanel:EnableMouse(true)
ledgerPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 18,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
ledgerPanel:SetBackdropColor(0.07, 0.06, 0.05, 0.98)
ledgerPanel:SetBackdropBorderColor(0.75, 0.60, 0.25, 1.0)
ledgerPanel:Hide()
main.ledgerPanel = ledgerPanel

local ledgerCloseBtn = CreateFrame("Button", nil, ledgerPanel, "UIPanelCloseButton")
ledgerCloseBtn:SetPoint("TOPRIGHT", -6, -6)

local ledgerTitle = ledgerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
ledgerTitle:SetPoint("TOPLEFT", 20, -16)
ledgerTitle:SetText("|cffd4a85aChronicleWeaver|r - Library Ledger & Export")

local ledgerTabMode = "LEDGER"
local ledgerTabBtn = CreateJournalUtilityButton(ledgerPanel, 156, 24, "Library Books Ledger")
ledgerTabBtn:SetPoint("TOPLEFT", 20, -46)

local exportTabBtn = CreateJournalUtilityButton(ledgerPanel, 130, 24, "Export & Share")
exportTabBtn:SetPoint("LEFT", ledgerTabBtn, "RIGHT", 8, 0)

-- Tab 1: Library Books Checklist
local ledgerContent = CreateFrame("Frame", nil, ledgerPanel)
ledgerContent:SetPoint("TOPLEFT", 18, -78)
ledgerContent:SetPoint("BOTTOMRIGHT", -18, 16)

local ledgerStats = ledgerContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
ledgerStats:SetPoint("TOPLEFT", 4, -4)
ledgerStats:SetPoint("RIGHT", -150, 0)
ledgerStats:SetJustifyH("LEFT")

local pinNearestBtn = CreateJournalUtilityButton(ledgerContent, 142, 22, "Pin Nearest Missing")
pinNearestBtn:SetPoint("TOPRIGHT", -4, 0)
pinNearestBtn:SetScript("OnClick", function()
    if ns.PinNearestMissingBook then
        ns.PinNearestMissingBook()
    end
end)

local LEDGER_VISIBLE_ROWS = 11
local ledgerScrollOffset = 0
local ledgerRows = {}
local isUpdatingLedgerScroll = false

local ledgerListBox = CreateFrame("Frame", nil, ledgerContent, "BackdropTemplate")
ledgerListBox:SetPoint("TOPLEFT", 0, -28)
ledgerListBox:SetPoint("BOTTOMRIGHT", 0, 24)
ledgerListBox:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
ledgerListBox:SetBackdropColor(0.05, 0.04, 0.04, 0.94)
ledgerListBox:SetBackdropBorderColor(0.45, 0.36, 0.22, 0.90)
ledgerListBox:EnableMouseWheel(true)

local ledgerScrollBar = CreateFrame("Slider", nil, ledgerListBox, "BackdropTemplate")
ledgerScrollBar:SetPoint("TOPRIGHT", -6, -8)
ledgerScrollBar:SetPoint("BOTTOMRIGHT", -6, 8)
ledgerScrollBar:SetWidth(8)
ledgerScrollBar:SetOrientation("VERTICAL")
local ledgerTrack = ledgerScrollBar:CreateTexture(nil, "BACKGROUND")
ledgerTrack:SetAllPoints()
ledgerTrack:SetColorTexture(0.04, 0.04, 0.05, 0.75)
local ledgerThumb = ledgerScrollBar:CreateTexture(nil, "OVERLAY")
ledgerThumb:SetSize(8, 24)
ledgerThumb:SetColorTexture(0.83, 0.66, 0.35, 0.90)
ledgerScrollBar:SetThumbTexture(ledgerThumb)
ledgerScrollBar:SetMinMaxValues(0, 0)
ledgerScrollBar:SetValueStep(1)
ledgerScrollBar:SetObeyStepOnDrag(true)

local ledgerTip = ledgerContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
ledgerTip:SetPoint("BOTTOMLEFT", 4, 4)
ledgerTip:SetText("Left-Click a book to pin spawn on World Map. Right-Click to toggle Turned In status.")

local function RenderLedgerRows()
    if not ns.LibraryBookCatalog then return end
    local bagSet = ns.GetBagItemIDSet and ns.GetBagItemIDSet() or {}
    local items = {}
    for _, book in ipairs(ns.LibraryBookCatalog) do
        if not ns.IsBookEligibleForPlayer or ns.IsBookEligibleForPlayer(book) then
            table.insert(items, book)
        end
    end

    local maxOffset = math.max(0, #items - LEDGER_VISIBLE_ROWS)
    ledgerScrollOffset = math.max(0, math.min(maxOffset, ledgerScrollOffset))
    isUpdatingLedgerScroll = true
    ledgerScrollBar:SetMinMaxValues(0, maxOffset)
    ledgerScrollBar:SetValue(ledgerScrollOffset)
    if maxOffset == 0 then ledgerScrollBar:Hide() else ledgerScrollBar:Show() end
    isUpdatingLedgerScroll = false

    for i = 1, LEDGER_VISIBLE_ROWS do
        local rowBtn = ledgerRows[i]
        local book = items[ledgerScrollOffset + i]
        if book then
            rowBtn.book = book
            local status = ns.GetLibraryBookStatus and ns.GetLibraryBookStatus(book.itemID, bagSet) or "MISSING"
            local badge = "|cff888888[Missing]|r"
            if status == "TURNED_IN" then
                badge = "|cff4cd964[Turned In]|r"
            elseif status == "IN_BAG" then
                badge = "|cff58a6ff[In Bag]|r"
            elseif status == "COLLECTED" then
                badge = "|cffffd100[Collected]|r"
            end
            local coordText = string.format("%s - %s (%.1f, %.1f)", book.zone, book.subzone or "", book.x * 100, book.y * 100)
            rowBtn.titleText:SetText(string.format("%s  |cfff2eee6%s|r", badge, book.title))
            rowBtn.locText:SetText("|cff99aabb" .. coordText .. "|r")
            rowBtn:Show()
        else
            rowBtn.book = nil
            rowBtn:Hide()
        end
    end

    if ns.GetLibraryProgressStats then
        local collected, inBag, total = ns.GetLibraryProgressStats()
        ledgerStats:SetText(string.format("|cffd4a85aProgress:|r %d / %d Collected (%d In Bags)  |  Milestones: 10 / 20 / 25",
            collected, total, inBag))
    end
end

for i = 1, LEDGER_VISIBLE_ROWS do
    local rowBtn = CreateFrame("Button", nil, ledgerListBox)
    rowBtn:SetHeight(25)
    rowBtn:SetPoint("TOPLEFT", 8, -8 - (i - 1) * 26)
    rowBtn:SetPoint("RIGHT", -20, 0)
    rowBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local hl = rowBtn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(0.85, 0.68, 0.35, 0.16)

    local zebra = rowBtn:CreateTexture(nil, "BACKGROUND")
    zebra:SetAllPoints()
    if i % 2 == 0 then
        zebra:SetColorTexture(0.10, 0.09, 0.08, 0.55)
    else
        zebra:SetColorTexture(0.06, 0.05, 0.05, 0.25)
    end

    local titleTextFS = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    titleTextFS:SetPoint("LEFT", 6, 0)
    titleTextFS:SetWidth(340)
    titleTextFS:SetJustifyH("LEFT")
    titleTextFS:SetWordWrap(false)
    rowBtn.titleText = titleTextFS

    local locTextFS = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    locTextFS:SetPoint("LEFT", titleTextFS, "RIGHT", 6, 0)
    locTextFS:SetPoint("RIGHT", -6, 0)
    locTextFS:SetJustifyH("RIGHT")
    locTextFS:SetWordWrap(false)
    rowBtn.locText = locTextFS

    rowBtn:SetScript("OnClick", function(self, button)
        if not self.book then return end
        if button == "RightButton" and ns.db then
            ns.db.completedLibraryBooks = ns.db.completedLibraryBooks or {}
            local id = self.book.itemID
            ns.db.completedLibraryBooks[id] = not ns.db.completedLibraryBooks[id] or nil
            RenderLedgerRows()
            if ns.UpdateWorldMapOverlay then ns.UpdateWorldMapOverlay() end
        elseif ns.SetMapPin then
            ns.SetMapPin(self.book.mapID, self.book.x, self.book.y, self.book.title .. " (" .. self.book.zone .. ")")
        end
    end)

    ledgerRows[i] = rowBtn
end

ledgerListBox:SetScript("OnMouseWheel", function(_, delta)
    ledgerScrollOffset = ledgerScrollOffset - delta * 2
    RenderLedgerRows()
end)

ledgerScrollBar:SetScript("OnValueChanged", function(_, value)
    if isUpdatingLedgerScroll then return end
    ledgerScrollOffset = math.floor(value + 0.5)
    RenderLedgerRows()
end)

-- Tab 2: Export & Share Modal
local exportContent = CreateFrame("Frame", nil, ledgerPanel)
exportContent:SetPoint("TOPLEFT", 18, -78)
exportContent:SetPoint("BOTTOMRIGHT", -18, 16)
exportContent:Hide()

local exportScroll = CreateFrame("ScrollFrame", nil, exportContent, "UIPanelScrollFrameTemplate")
exportScroll:SetPoint("TOPLEFT", 4, -34)
exportScroll:SetPoint("BOTTOMRIGHT", -24, 24)

local exportEditBox = CreateFrame("EditBox", nil, exportScroll)
exportEditBox:SetMultiLine(true)
exportEditBox:SetWidth(580)
exportEditBox:SetFontObject("ChatFontNormal")
exportEditBox:SetAutoFocus(false)
exportEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
exportScroll:SetScrollChild(exportEditBox)

local exportMdBtn = CreateJournalUtilityButton(exportContent, 174, 24, "Current Entry (Markdown)")
exportMdBtn:SetPoint("TOPLEFT", 4, 0)
exportMdBtn:SetScript("OnClick", function()
    local text = ns.ExportEntryToMarkdown and ns.ExportEntryToMarkdown(ns.selectedKey) or ""
    exportEditBox:SetText(text)
    exportEditBox:SetFocus()
    exportEditBox:HighlightText()
end)

local exportLuaBtn = CreateJournalUtilityButton(exportContent, 146, 24, "All Harvests (Lua)")
exportLuaBtn:SetPoint("LEFT", exportMdBtn, "RIGHT", 8, 0)
exportLuaBtn:SetScript("OnClick", function()
    local text = ns.ExportHarvestedToLua and ns.ExportHarvestedToLua() or ""
    exportEditBox:SetText(text)
    exportEditBox:SetFocus()
    exportEditBox:HighlightText()
end)

local selectAllBtn = CreateJournalUtilityButton(exportContent, 96, 24, "Select All")
selectAllBtn:SetPoint("LEFT", exportLuaBtn, "RIGHT", 8, 0)
selectAllBtn:SetScript("OnClick", function()
    exportEditBox:SetFocus()
    exportEditBox:HighlightText()
end)

local exportTip = exportContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
exportTip:SetPoint("BOTTOMLEFT", 4, 4)
exportTip:SetText("Press Ctrl+C while highlighted to copy Markdown or Lua data for guides, Discord, or contributions.")

local function ApplyLedgerTab()
    if ledgerTabMode == "EXPORT" then
        ledgerContent:Hide()
        exportContent:Show()
        ledgerTabBtn:SetBackdropBorderColor(0.40, 0.32, 0.20, 1.0)
        exportTabBtn:SetBackdropBorderColor(0.95, 0.78, 0.35, 1.0)
        if exportEditBox:GetText() == "" and ns.ExportEntryToMarkdown then
            exportEditBox:SetText(ns.ExportEntryToMarkdown(ns.selectedKey))
        end
    else
        exportContent:Hide()
        ledgerContent:Show()
        ledgerTabBtn:SetBackdropBorderColor(0.95, 0.78, 0.35, 1.0)
        exportTabBtn:SetBackdropBorderColor(0.40, 0.32, 0.20, 1.0)
        RenderLedgerRows()
    end
end

ledgerTabBtn:SetScript("OnClick", function()
    ledgerTabMode = "LEDGER"
    ApplyLedgerTab()
end)

exportTabBtn:SetScript("OnClick", function()
    ledgerTabMode = "EXPORT"
    if ns.ExportEntryToMarkdown then
        exportEditBox:SetText(ns.ExportEntryToMarkdown(ns.selectedKey))
    end
    ApplyLedgerTab()
end)

function ns.RefreshLedgerPanel()
    if not ledgerPanel or not ledgerPanel:IsShown() then return end
    ApplyLedgerTab()
end

function ns.ToggleLedgerPanel(mode)
    if not ledgerPanel then return end
    if optionsPanel and optionsPanel:IsShown() then
        optionsPanel:Hide()
    end
    if mode == "LEDGER" or mode == "EXPORT" then
        ledgerTabMode = mode
        ledgerPanel:Show()
        ApplyLedgerTab()
    elseif ledgerPanel:IsShown() then
        ledgerPanel:Hide()
    else
        ledgerPanel:Show()
        ApplyLedgerTab()
    end
end

function ns.ToggleOptionsPanel(forceShow)
    if not optionsPanel then return end
    if ledgerPanel and ledgerPanel:IsShown() then
        ledgerPanel:Hide()
    end
    if forceShow == true or not optionsPanel:IsShown() then
        ns.RefreshOptionsPanel()
        optionsPanel:Show()
    else
        optionsPanel:Hide()
    end
end

-- -------------------------------------------------------------------------
-- Window State Handlers
-- -------------------------------------------------------------------------
function ns.RestoreWindowPosition()
    if ns.db and ns.db.windowPos and not InCombatLockdown() then
        local pos = ns.db.windowPos
        main:ClearAllPoints()
        main:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
        local w = pos.width or 980
        local h = pos.height or 660
        main:SetSize(w, h)
        if main.listPanel then
            local targetWidth = math.floor(math.min(360, math.max(260, w * 0.28)))
            main.listPanel:SetWidth(targetWidth)
        end
    end
end

function ns.ToggleMainFrame()
    if main:IsShown() then
        main:Hide()
    else
        ns.RestoreWindowPosition()
        if ns.ApplyTheme then ns.ApplyTheme() end
        main:Show()
        if ns.RefreshUI then ns.RefreshUI() end
    end
end

function ns.ShowMainFrame()
    ns.RestoreWindowPosition()
    if ns.ApplyTheme then ns.ApplyTheme() end
    main:Show()
    if ns.RefreshUI then ns.RefreshUI() end
end

main:SetScript("OnShow", function()
    if ns.ApplyTheme then ns.ApplyTheme() end
    if ns.RefreshUI then ns.RefreshUI() end
    if ns.RefreshOptionsPanel and optionsPanel:IsShown() then
        ns.RefreshOptionsPanel()
    end
end)
