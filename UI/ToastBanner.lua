-- =========================================================================
-- UI/ToastBanner.lua
-- Animated discovery fanfare banner with icon frame and click-to-open.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

local toast = CreateFrame("Button", "ChronicleWeaverToastFrame", UIParent, "BackdropTemplate")
toast:SetSize(340, 60)
toast:SetPoint("TOP", 0, -120)
toast:SetFrameStrata("DIALOG")
toast:SetMovable(true)
toast:EnableMouse(true)
toast:RegisterForDrag("LeftButton")
toast:SetScript("OnDragStart", function(self) self:StartMoving() end)
toast:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

toast:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
toast:SetBackdropColor(0.08, 0.08, 0.10, 0.96)
toast:SetBackdropBorderColor(0.83, 0.66, 0.35, 1.0)
toast:Hide()

-- Framed 38x38 Icon on the left
local iconFrame = CreateFrame("Frame", nil, toast, "BackdropTemplate")
iconFrame:SetSize(40, 40)
iconFrame:SetPoint("LEFT", 10, 0)
iconFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
iconFrame:SetBackdropBorderColor(0.83, 0.66, 0.35, 1.0)

local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
iconTex:SetPoint("TOPLEFT", 2, -2)
iconTex:SetPoint("BOTTOMRIGHT", -2, 2)
iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
toast.iconTex = iconTex

-- Header FontString
local toastHeader = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
toastHeader:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -2)
toastHeader:SetText("|cffd4a85aNEW LORE DISCOVERED|r")

-- Title FontString
local toastTitle = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
toastTitle:SetPoint("TOPLEFT", toastHeader, "BOTTOMLEFT", 0, -4)
toastTitle:SetPoint("RIGHT", -12, 0)
toastTitle:SetJustifyH("LEFT")
toastTitle:SetWordWrap(false)
if toastTitle.SetMaxLines then toastTitle:SetMaxLines(1) end

toast:SetScript("OnClick", function(self)
    if self.entryKey then
        if ns.SelectEntry then
            ns.SelectEntry(self.entryKey)
        end
        if ns.ToggleMainFrame then
            ns.ToggleMainFrame()
        elseif ChronicleWeaverMainFrame then
            ChronicleWeaverMainFrame:Show()
        end
        self:Hide()
    end
end)

function ns.ShowDiscoveryToast(entry, isSynthesis)
    if not entry or (ns.db and not ns.db.autoToast) then return end

    toast.entryKey = entry.key
    toastTitle:SetText(entry.title or "Unknown Discovery")

    local iconPath = entry.icon
        or (ns.CategoryIcons and ns.CategoryIcons[entry.category])
        or "Interface\\Icons\\INV_Misc_Book_09"
    toast.iconTex:SetTexture(iconPath)

    if isSynthesis or entry.category == "Dossier" then
        toast:SetBackdropBorderColor(0.77, 0.52, 0.75, 1.0)
        iconFrame:SetBackdropBorderColor(0.77, 0.52, 0.75, 1.0)
        toastHeader:SetText("|cffc586c0LORE DOSSIER EVIDENCE UNCOVERED|r")
    else
        toast:SetBackdropBorderColor(0.83, 0.66, 0.35, 1.0)
        iconFrame:SetBackdropBorderColor(0.83, 0.66, 0.35, 1.0)
        toastHeader:SetText("|cffd4a85aNEW LORE DISCOVERED|r")
    end

    -- Play gentle discovery sound if available
    pcall(PlaySound, SOUNDKIT and SOUNDKIT.UI_QUEST_PVP_COMPLETE or 878)

    toast:Show()
    if C_Timer and C_Timer.After then
        C_Timer.After(6.0, function()
            if toast:IsShown() and toast.entryKey == entry.key then
                toast:Hide()
            end
        end)
    end
end
