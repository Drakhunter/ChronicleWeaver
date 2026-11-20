-- =========================================================================
-- UI/ToastBanner.lua
-- Animated discovery fanfare banner with icon frame and click-to-open.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

local toast = CreateFrame("Button", "ChronicleWeaverToastFrame", UIParent, "BackdropTemplate")
toast:SetSize(340, 60)
toast:SetPoint("TOP", 0, -120)
toast:SetFrameStrata("DIALOG")
toast:SetMovable(true)
toast:EnableMouse(true)
toast:RegisterForDrag("LeftButton")
toast:SetScript("OnDragStart", function(self)
    if ns.db and ns.db.toastLocked then return end
    self:StartMoving()
end)
toast:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if ns.db then
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.toastPos = { point = point or "TOP", relPoint = relPoint or "TOP", x = x or 0, y = y or -120 }
    end
end)

local function ApplyToastPosition()
    if ns.db and ns.db.toastPos then
        local pos = ns.db.toastPos
        toast:ClearAllPoints()
        toast:SetPoint(pos.point or "TOP", UIParent, pos.relPoint or "TOP", pos.x or 0, pos.y or -120)
    end
end

function ns.ResetToastPosition()
    if ns.db then
        ns.db.toastPos = { point = "TOP", relPoint = "TOP", x = 0, y = -120 }
    end
    ApplyToastPosition()
end

function ns.PlayChronicleSound(customStyle)
    if ns.db and ns.db.toastSound == false then return end
    local style = customStyle or (ns.db and ns.db.soundStyle) or "CHIME"
    if style == "MUTE" then return end
    local soundID = 878
    if style == "PAGETURN" then
        soundID = 847
    elseif style == "FANFARE" then
        soundID = 619
    elseif SOUNDKIT and SOUNDKIT.UI_QUEST_PVP_COMPLETE then
        soundID = SOUNDKIT.UI_QUEST_PVP_COMPLETE
    end
    pcall(PlaySound, soundID)
end

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
    if self.compassPin then
        local pin = self.compassPin
        if ns.SetMapPin then
            ns.SetMapPin(pin.mapID, pin.x, pin.y, pin.label)
        end
        self:Hide()
    elseif self.entryKey then
        if ns.SelectEntry then
            ns.SelectEntry(self.entryKey)
        end
        if ns.ShowMainFrame then
            ns.ShowMainFrame()
        elseif ns.ToggleMainFrame then
            ns.ToggleMainFrame()
        elseif ChronicleWeaverMainFrame then
            ChronicleWeaverMainFrame:Show()
        end
        self:Hide()
    end
end)

local function ScheduleToastAutoHide(token)
    if C_Timer and C_Timer.After then
        C_Timer.After(6.0, function()
            if toast:IsShown() and toast.displayToken == token then
                toast:Hide()
            end
        end)
    end
end

function ns.ShowDiscoveryToast(entry, isSynthesis)
    if not entry or (ns.db and not ns.db.autoToast) then return end

    local token = (toast.displayToken or 0) + 1
    toast.displayToken = token
    toast.compassPin = nil
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

    ApplyToastPosition()
    ns.PlayChronicleSound()
    toast:Show()
    ScheduleToastAutoHide(token)
end

function ns.ShowCompassWhisperToast(title, zoneText, mapID, x, y)
    if ns.db and ns.db.autoToast == false then return end

    local token = (toast.displayToken or 0) + 1
    toast.displayToken = token
    toast.entryKey = nil
    toast.compassPin = {
        mapID = mapID,
        x = x,
        y = y,
        label = (title or "Nearby Chronicle") .. (zoneText and (" (" .. zoneText .. ")") or ""),
    }

    toast.iconTex:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_02")
    toast:SetBackdropBorderColor(0.30, 0.78, 0.45, 1.0)
    iconFrame:SetBackdropBorderColor(0.30, 0.78, 0.45, 1.0)
    toastHeader:SetText("|cff4cd964ARCHIVIST'S COMPASS - NEARBY CHRONICLE|r")
    toastTitle:SetText((title or "Unrecorded Lore") .. " (Click to Pin)")

    ApplyToastPosition()
    ns.PlayChronicleSound("PAGETURN")
    toast:Show()
    ScheduleToastAutoHide(token)
end
