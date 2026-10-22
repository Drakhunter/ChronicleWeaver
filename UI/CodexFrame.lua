-- =========================================================================
-- UI/CodexFrame.lua
-- Main Codex window: category filter, search, scrollable entry list,
-- lore reader and personal field notes.
-- =========================================================================
local _, ns = ...
local L = ns.L
local Theme = ns.Theme

local CATEGORY_ALL = "ALL"
local LIST_ROW_HEIGHT = 28

local state = {
    category = CATEGORY_ALL,
    query = "",
    selectedKey = nil,
}

local Refresh -- forward declaration

-- -------------------------------------------------------------------------
-- Window
-- -------------------------------------------------------------------------
local main = Theme.CreateBackdropFrame("Frame", UIParent, "window", "ChronicleWeaverMainFrame")
main:SetSize(720, 520)
main:SetPoint("CENTER")
main:SetFrameStrata("DIALOG")
main:SetToplevel(true)
main:SetClampedToScreen(true)
main:SetMovable(true)
main:EnableMouse(true)
main:RegisterForDrag("LeftButton")
main:Hide()
tinsert(UISpecialFrames, main:GetName()) -- close with Escape

main:SetScript("OnDragStart", main.StartMoving)
main:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    ns.db.windowPos = { point = point, relPoint = relPoint, x = x, y = y }
end)

local function RestorePosition()
    local pos = ns.db.windowPos
    main:ClearAllPoints()
    main:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

local titleText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 18, -16)
titleText:SetText(ns.Colorize(ns.COLORS.gold, ns.name) .. " - " .. L.SUBTITLE)

local closeBtn = CreateFrame("Button", nil, main, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -6, -6)

local spoilerBtn = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
spoilerBtn:SetSize(145, 22)
spoilerBtn:SetPoint("TOPRIGHT", -42, -14)
spoilerBtn:SetScript("OnClick", function()
    ns.ToggleOption("spoilerFree")
end)

-- -------------------------------------------------------------------------
-- Category filter & search
-- -------------------------------------------------------------------------
local categoryButtons = {}
do
    local filters = { CATEGORY_ALL }
    for _, cat in ipairs(ns.CATEGORIES) do filters[#filters + 1] = cat end

    for i, cat in ipairs(filters) do
        local btn = CreateFrame("Button", nil, main, "UIPanelButtonTemplate")
        btn:SetSize(62, 22)
        btn:SetPoint("TOPLEFT", 18 + (i - 1) * 65, -44)
        btn:SetText(cat == CATEGORY_ALL and L.ALL or L[cat])
        btn:SetScript("OnClick", function()
            state.category = cat
            Refresh()
        end)
        categoryButtons[cat] = btn
    end
end

local searchBox = CreateFrame("EditBox", nil, main, "SearchBoxTemplate")
searchBox:SetSize(195, 22)
searchBox:SetPoint("TOPRIGHT", -18, -44)
searchBox:SetAutoFocus(false)
searchBox:HookScript("OnTextChanged", function(self)
    state.query = (self:GetText() or ""):lower()
    Refresh()
end)

-- -------------------------------------------------------------------------
-- Entry list (ScrollBox)
-- -------------------------------------------------------------------------
local listPanel = Theme.CreateBackdropFrame("Frame", main, "list")
listPanel:SetPoint("TOPLEFT", 16, -74)
listPanel:SetPoint("BOTTOMLEFT", 16, 16)
listPanel:SetWidth(240)

local scrollBox = CreateFrame("Frame", nil, listPanel, "WowScrollBoxList")
scrollBox:SetPoint("TOPLEFT", 6, -6)
scrollBox:SetPoint("BOTTOMRIGHT", -20, 6)

local scrollBar = CreateFrame("EventFrame", nil, listPanel, "MinimalScrollBar")
scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

local function OnListButtonClick(button)
    state.selectedKey = button.entryKey
    Refresh()
end

local view = CreateScrollBoxListLinearView()
view:SetElementExtent(LIST_ROW_HEIGHT)
view:SetElementInitializer("ChronicleWeaverListButtonTemplate", function(button, entry)
    button.entryKey = entry.key
    local marker = ns.IsDiscovered(entry.key)
        and ns.Colorize(ns.COLORS.green, " ")
        or ns.Colorize("777777", "...")
    button.Text:SetText(marker .. " " .. entry.title)
    button.Selected:SetShown(entry.key == state.selectedKey)
    button:SetScript("OnClick", OnListButtonClick)
end)
ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

-- -------------------------------------------------------------------------
-- Reader panel
-- -------------------------------------------------------------------------
local reader = Theme.CreateBackdropFrame("Frame", main, "reader")
reader:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 10, 0)
reader:SetPoint("BOTTOMRIGHT", -16, 16)

local heading = reader:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
heading:SetPoint("TOPLEFT", 16, -16)
heading:SetPoint("RIGHT", -130, 0)
heading:SetJustifyH("LEFT")

local pinBtn = CreateFrame("Button", nil, reader, "UIPanelButtonTemplate")
pinBtn:SetSize(105, 22)
pinBtn:SetPoint("TOPRIGHT", -14, -14)
pinBtn:SetText(L.PIN_TO_MAP)
pinBtn:SetScript("OnClick", function()
    ns.PinEntryToMap(state.selectedKey)
end)

local meta = reader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
meta:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -4)
meta:SetTextColor(unpack(Theme.TEXT_META))

local summary = reader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
summary:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -10)
summary:SetPoint("RIGHT", -16, 0)
summary:SetJustifyH("LEFT")
summary:SetTextColor(unpack(Theme.TEXT_SUMMARY))

-- Notes (bottom), reveal button and scrollable story (middle)
local notesBg = Theme.CreateBackdropFrame("Frame", reader, "input")
notesBg:SetPoint("BOTTOMLEFT", 14, 14)
notesBg:SetPoint("BOTTOMRIGHT", -14, 14)
notesBg:SetHeight(66)

local notesLabel = reader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
notesLabel:SetPoint("BOTTOMLEFT", notesBg, "TOPLEFT", 2, 6)
notesLabel:SetText(ns.Colorize(ns.COLORS.gold, L.NOTES_LABEL))

local notesBox = CreateFrame("EditBox", nil, notesBg)
notesBox:SetMultiLine(true)
notesBox:SetFontObject("ChatFontNormal")
notesBox:SetPoint("TOPLEFT", 8, -8)
notesBox:SetPoint("BOTTOMRIGHT", -8, 8)
notesBox:SetAutoFocus(false)
notesBox:SetMaxLetters(2000)
notesBox:SetScript("OnEscapePressed", notesBox.ClearFocus)
notesBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput and self.entryKey then
        local text = self:GetText()
        ns.db.notes[self.entryKey] = (text ~= "") and text or nil
    end
end)

local revealBtn = CreateFrame("Button", nil, reader, "UIPanelButtonTemplate")
revealBtn:SetSize(170, 24)
revealBtn:SetPoint("BOTTOMLEFT", notesLabel, "TOPLEFT", -2, 8)
revealBtn:SetText(L.UNLOCK_MANUALLY)
revealBtn:SetScript("OnClick", function()
    ns.UnlockEntry(state.selectedKey)
end)

local storyScroll = CreateFrame("ScrollFrame", nil, reader, "ScrollFrameTemplate")
storyScroll:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -12)
storyScroll:SetPoint("BOTTOMRIGHT", reader, "BOTTOMRIGHT", -30, 132)

local storyChild = CreateFrame("Frame", nil, storyScroll)
storyChild:SetSize(1, 1)
storyScroll:SetScrollChild(storyChild)

local story = storyChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
story:SetPoint("TOPLEFT")
story:SetJustifyH("LEFT")
story:SetSpacing(3)

local function SetStoryText(text)
    local width = storyScroll:GetWidth()
    storyChild:SetWidth(width)
    story:SetWidth(width)
    story:SetText(text)
    storyChild:SetHeight(math.max(story:GetStringHeight(), 1))
    storyScroll:SetVerticalScroll(0)
end

-- -------------------------------------------------------------------------
-- Render pipeline
-- -------------------------------------------------------------------------
local function MatchesFilter(entry)
    if state.category ~= CATEGORY_ALL and entry.category ~= state.category then
        return false
    end
    if state.query == "" then return true end
    return entry.title:lower():find(state.query, 1, true) ~= nil
        or entry.summary:lower():find(state.query, 1, true) ~= nil
end

local function RenderList()
    local filtered = {}
    for _, entry in ipairs(ns.LoreEntries) do
        if MatchesFilter(entry) then
            filtered[#filtered + 1] = entry
        end
    end

    if not state.selectedKey and filtered[1] then
        state.selectedKey = filtered[1].key
    end

    scrollBox:SetDataProvider(CreateDataProvider(filtered), ScrollBoxConstants.RetainScrollPosition)

    for cat, btn in pairs(categoryButtons) do
        btn:SetEnabled(cat ~= state.category)
    end
end

local function RenderEntry(entry)
    -- Don't clobber notes the player is currently typing for this entry
    local editingSame = notesBox:HasFocus() and notesBox.entryKey == (entry and entry.key)
    notesBox.entryKey = entry and entry.key
    if not editingSame then
        notesBox:SetText(entry and ns.db.notes[entry.key] or "")
    end

    if not entry then
        heading:SetText(L.NO_SELECTION)
        meta:SetText("")
        summary:SetText("")
        SetStoryText("")
        revealBtn:Hide()
        pinBtn:Hide()
        return
    end

    local discovered = ns.IsDiscovered(entry.key)
    heading:SetText(entry.title)
    meta:SetText(("%s     %s     %s"):format(
        L[entry.category],
        entry.era,
        discovered and ns.Colorize(ns.COLORS.green, L.DISCOVERED) or ns.Colorize(ns.COLORS.orange, L.UNDISCOVERED)
    ))
    summary:SetText(entry.summary)
    pinBtn:SetShown(ns.HasCoordinates(entry))

    if ns.CanReveal(entry.key) then
        SetStoryText(entry.story)
        revealBtn:Hide()
    else
        SetStoryText(ns.Colorize(ns.COLORS.grey, L.SPOILER_PLACEHOLDER))
        revealBtn:Show()
    end
end

function Refresh()
    if not ns.db or not main:IsShown() then return end

    spoilerBtn:SetText(ns.db.spoilerFree and L.SPOILERS_HIDDEN or L.SPOILERS_SHOWN)
    RenderList()
    RenderEntry(state.selectedKey and ns.LoreByKey[state.selectedKey])
end

main:SetScript("OnShow", Refresh)

ns.RegisterMessage("ENTRY_UNLOCKED", Refresh)
ns.RegisterMessage("CODEX_UPDATED", Refresh)
ns.RegisterMessage("OPTION_CHANGED", Refresh)
ns.OnAddonLoaded(RestorePosition)

-- -------------------------------------------------------------------------
-- Public API
-- -------------------------------------------------------------------------
function ns.ToggleMainFrame()
    main:SetShown(not main:IsShown())
end

--- Opens the Codex with a specific entry selected.
function ns.ShowEntry(entryKey)
    state.selectedKey = entryKey
    if main:IsShown() then
        Refresh()
    else
        main:Show() -- OnShow refreshes
    end
end
