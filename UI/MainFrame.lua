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

-- Grouping Mode Cycle Button ("Group: Zone/Flat")
local groupBtn = CreateJournalUtilityButton(main, 96, 22, "Group: Zone")
groupBtn:SetPoint("RIGHT", factionBtn, "LEFT", -6, 0)
groupBtn:SetScript("OnClick", function()
    if not ns.db then return end
    local cur = ns.db.groupMode or "ZONE"
    if cur == "ZONE" then
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
    GameTooltip:AddLine("Left-Click: Toggle between Zone Folders and Flat List", 0.9, 0.9, 0.9)
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
    Zone = 68,
    Dungeon = 82,
    NPC = 62,
    Relic = 68,
    Book = 68,
    Quest = 72,
    Dossier = 80,
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
local startX = 16
for _, cat in ipairs(categories) do
    local width = catWidths[cat] or 60
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
    icon:SetPoint("LEFT", 6, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetTexture(catIcons[cat] or "Interface\\Icons\\INV_Misc_Book_09")
    btn.icon = icon

    -- Tab Label
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    text:SetPoint("RIGHT", -4, 0)
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
    startX = startX + width + 4
end
main.catButtons = catButtons

-- Live Search Box (Sleek Dark Obsidian Input)
local searchBox = CreateFrame("EditBox", nil, main, "BackdropTemplate")
searchBox:SetSize(160, 24)
searchBox:SetPoint("TOPRIGHT", -16, -46)
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
end)
