-- =========================================================================
-- UI/Theme.lua
-- Shared backdrops and colors for all ChronicleWeaver frames.
-- =========================================================================
local _, ns = ...

local Theme = {}
ns.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8x8"
local TOOLTIP_BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
local DIALOG_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"

-- backdrop + background color + optional border color
local STYLES = {
    window = {
        backdrop = { bgFile = WHITE, edgeFile = DIALOG_BORDER, edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } },
        bg = { 0.09, 0.08, 0.07, 0.96 },
    },
    toast = {
        backdrop = { bgFile = WHITE, edgeFile = TOOLTIP_BORDER, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } },
        bg = { 0.08, 0.07, 0.06, 0.94 },
        border = { 0.83, 0.66, 0.35, 1 },
    },
    list = {
        backdrop = { bgFile = WHITE, edgeFile = TOOLTIP_BORDER, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } },
        bg = { 0.05, 0.05, 0.05, 0.9 },
    },
    reader = {
        backdrop = { bgFile = WHITE, edgeFile = TOOLTIP_BORDER, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } },
        bg = { 0.06, 0.05, 0.04, 0.9 },
    },
    input = {
        backdrop = { bgFile = WHITE, edgeFile = TOOLTIP_BORDER, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } },
        bg = { 0.03, 0.03, 0.03, 0.95 },
    },
}

--- Creates a frame that inherits BackdropTemplate and applies a named style.
--- @param frameType string
--- @param parent Frame
--- @param style string key of STYLES
--- @param name string|nil global frame name
function Theme.CreateBackdropFrame(frameType, parent, style, name)
    local frame = CreateFrame(frameType, name, parent, "BackdropTemplate")
    local s = STYLES[style]
    frame:SetBackdrop(s.backdrop)
    frame:SetBackdropColor(unpack(s.bg))
    if s.border then
        frame:SetBackdropBorderColor(unpack(s.border))
    end
    return frame
end

-- RGB colors for FontString:SetTextColor
Theme.TEXT_META = { 0.65, 0.75, 0.85 }
Theme.TEXT_SUMMARY = { 0.95, 0.85, 0.55 }
