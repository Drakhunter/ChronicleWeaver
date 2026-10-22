-- =========================================================================
-- UI/Toast.lua
-- "New lore discovered" banner. Click to open the entry in the Codex.
-- =========================================================================
local _, ns = ...
local L = ns.L

local DISPLAY_SECONDS = 6

local toast = ns.Theme.CreateBackdropFrame("Button", UIParent, "toast", "ChronicleWeaverToastFrame")
toast:SetSize(320, 58)
toast:SetPoint("TOP", 0, -120)
toast:SetFrameStrata("HIGH")
toast:Hide()

local header = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
header:SetPoint("TOPLEFT", 14, -10)
header:SetText(ns.Colorize(ns.COLORS.gold, L.TOAST_HEADER))

local title = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
title:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
title:SetPoint("RIGHT", -14, 0)
title:SetJustifyH("LEFT")
title:SetWordWrap(false)

toast:SetScript("OnClick", function(self)
    self:Hide()
    if self.entryKey then
        ns.ShowEntry(self.entryKey)
    end
end)

toast:SetScript("OnHide", function(self)
    if self.timer then
        self.timer:Cancel()
        self.timer = nil
    end
end)

local function ShowToast(entry)
    if not ns.db.autoToast then return end

    toast.entryKey = entry.key
    title:SetText(entry.title)
    if toast.timer then toast.timer:Cancel() end
    toast.timer = C_Timer.NewTimer(DISPLAY_SECONDS, function() toast:Hide() end)
    toast:Show()
end

ns.RegisterMessage("ENTRY_UNLOCKED", ShowToast)
