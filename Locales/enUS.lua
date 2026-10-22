-- =========================================================================
-- Locales/enUS.lua
-- English UI strings. Missing keys fall back to the key itself, so category
-- names like L["Dungeon"] work without an explicit entry.
-- Note: lore content in Data/LoreDB.lua is intentionally not localized here.
-- =========================================================================
local _, ns = ...

local L = setmetatable({}, {
    __index = function(t, key)
        rawset(t, key, key)
        return key
    end,
})
ns.L = L

-- General
L.SUBTITLE = "WoW: Forever Lore Codex"
L.ENABLED = "Enabled"
L.DISABLED = "Disabled"
L.UNKNOWN_ZONE = "Unknown Zone"

-- Options
L.OPTION_SPOILER = "Spoiler-Safe Mode"
L.OPTION_SPOILER_TOOLTIP = "Hide the full story of an entry until you discover it in Azeroth."
L.OPTION_TOAST = "Discovery Toasts"
L.OPTION_TOAST_TOOLTIP = "Show a banner when you discover a new lore entry."

-- Slash commands
L.CMD_HELP_HEADER = "Commands:"
L.CMD_HELP_TOGGLE = "/cw - Toggle the Lore Codex"
L.CMD_HELP_SPOILERS = "/cw spoilers - Toggle Spoiler-Safe Mode"
L.CMD_HELP_TOAST = "/cw toast - Toggle discovery toasts"
L.CMD_HELP_OPTIONS = "/cw options - Open the settings panel"

-- Addon compartment
L.COMPARTMENT_LEFT = "Left-Click: Toggle Lore Codex"
L.COMPARTMENT_RIGHT = "Right-Click: Toggle Spoiler-Safe Mode"

-- Map pins
L.PIN_NO_COORDS = "No exact map coordinates recorded for this entry yet."
L.PIN_UNAVAILABLE = "Cannot place a waypoint on this map."
L.PIN_SUCCESS = "Pinned %s to your World Map (%.1f, %.1f)!"

-- Tooltips
L.TOOLTIP_HEADER = "[ChronicleWeaver Lore]"
L.TOOLTIP_LOCKED_NPC = "Target this character to unlock their chronicle entry."

-- Books
L.BOOK_PAGE_HEADER = "--- Page %d ---"
L.BOOK_ERA = "In-Game Text (%dp)"
L.BOOK_FOUND_IN = "Discovered in %s"
L.BOOK_COORDS = " at %.1f, %.1f"

-- Toast
L.TOAST_HEADER = "NEW LORE DISCOVERED"

-- Codex window
L.ALL = "All"
L.SPOILERS_HIDDEN = "Spoilers: Hidden"
L.SPOILERS_SHOWN = "Spoilers: Shown"
L.PIN_TO_MAP = "Pin to Map"
L.UNLOCK_MANUALLY = "Unlock Entry Manually"
L.NOTES_LABEL = "Personal Field Notes (Auto-Saved):"
L.NO_SELECTION = "No Lore Entry Selected"
L.DISCOVERED = "Discovered"
L.UNDISCOVERED = "Undiscovered"
L.SPOILER_PLACEHOLDER = "[Spoiler-Safe Mode Active: Visit this location or target this character in Azeroth to unlock the full story, or click below to reveal it now.]"
