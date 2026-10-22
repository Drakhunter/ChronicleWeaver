-- =========================================================================
-- Core/Constants.lua
-- Theme palettes, category icons/tags, media paths, and global constants.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

-- -------------------------------------------------------------------------
-- Media Path
-- -------------------------------------------------------------------------
ns.MediaPath = "Interface\\AddOns\\" .. addonName .. "\\Media\\"

-- -------------------------------------------------------------------------
-- Shared Color Palette (Hex)
-- -------------------------------------------------------------------------
ns.COLORS = {
    gold      = "d4a85a",
    highlight = "ffd100",
    crimson   = "7a1c14",
    green     = "4cd964",
    red       = "ff3b30",
    orange    = "ff9500",
    blue      = "58a6ff",
    purple    = "a335ee",
    grey      = "888888",
    ivory     = "f4eee0",
    slate     = "1f232a",
    parchment = "e8dec8",
}

-- -------------------------------------------------------------------------
-- Category Icons (Real Built-in WoW Textures)
-- -------------------------------------------------------------------------
ns.CategoryIcons = {
    Zone    = "Interface\\Icons\\INV_Misc_Map_01",
    Dungeon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    NPC     = "Interface\\Icons\\INV_Misc_Head_Human_01",
    Relic   = "Interface\\Icons\\INV_Misc_Gem_Variety_01",
    Book    = "Interface\\Icons\\INV_Misc_Book_09",
    Quest   = "Interface\\Icons\\INV_Misc_Note_01",
    Dossier = "Interface\\Icons\\INV_Misc_Spyglass_02",
    Gossip  = "Interface\\Icons\\INV_Misc_Note_02",
    Default = "Interface\\Icons\\INV_Misc_Book_09",
}

-- -------------------------------------------------------------------------
-- Category Tags (Pure ASCII, Color-Coded, Zero Unicode)
-- -------------------------------------------------------------------------
ns.CategoryTags = {
    Zone    = "|cff4cd964[Z]|r",
    Dungeon = "|cffff8000[D]|r",
    NPC     = "|cff58a6ff[N]|r",
    Relic   = "|cffa335ee[R]|r",
    Book    = "|cffd4a85a[B]|r",
    Quest   = "|cffffd100[Q]|r",
    Dossier = "|cffe5c07b[!]|r",
    Gossip  = "|cff58d68d[G]|r",
    Default = "|cffaaaaaa[*]|r",
}

-- -------------------------------------------------------------------------
-- Ordered Categories for Main Navigation Tabs
-- -------------------------------------------------------------------------
ns.CATEGORIES = { "Zone", "Dungeon", "NPC", "Relic", "Book", "Quest", "Dossier" }

-- -------------------------------------------------------------------------
-- Dual-Theme Palettes: "PARCHMENT" (Royal Archivist) vs. "DARK" (Midnight)
-- -------------------------------------------------------------------------
ns.THEMES = {
    PARCHMENT = {
        name         = "Parchment",
        isDark       = false,
        bgFile       = "Interface\\Buttons\\WHITE8X8",
        windowBg     = { r = 0.08, g = 0.07, b = 0.06, a = 0.98 },
        sidebarBg    = { r = 0.06, g = 0.05, b = 0.05, a = 0.95 },
        cardBg       = { r = 0.91, g = 0.85, b = 0.73, a = 1.00 },
        cardBorder   = { r = 0.65, g = 0.50, b = 0.28, a = 1.00 },
        border       = { r = 0.40, g = 0.35, b = 0.25, a = 0.85 },
        borderGold   = { r = 0.70, g = 0.55, b = 0.20, a = 1.00 },
        titleText    = { r = 0.32, g = 0.14, b = 0.04 },
        headerText   = { r = 0.28, g = 0.12, b = 0.04 },
        bodyText     = { r = 0.14, g = 0.10, b = 0.06 },
        mutedText    = { r = 0.42, g = 0.30, b = 0.18 },
        summaryText  = { r = 0.48, g = 0.24, b = 0.06 },
        accentText   = { r = 0.55, g = 0.38, b = 0.14 },
        highlightHex = "7a1c14", -- Deep Crimson for parchment contrast
        notesBg      = { r = 0.85, g = 0.78, b = 0.65, a = 1.00 },
        notesBorder  = { r = 0.58, g = 0.44, b = 0.26, a = 1.00 },
        notesText    = { r = 0.14, g = 0.10, b = 0.06 },
        clueBg       = { r = 0.83, g = 0.75, b = 0.61, a = 0.95 },
        clueBorder   = { r = 0.58, g = 0.44, b = 0.26, a = 1.00 },
        clueTitle    = { r = 0.18, g = 0.11, b = 0.05 },
        clueMeta     = { r = 0.42, g = 0.30, b = 0.18 },
    },
    DARK = {
        name         = "Midnight Obsidian",
        isDark       = true,
        bgFile       = "Interface\\Buttons\\WHITE8X8",
        windowBg     = { r = 0.08, g = 0.07, b = 0.06, a = 0.98 },
        sidebarBg    = { r = 0.06, g = 0.05, b = 0.05, a = 0.95 },
        cardBg       = { r = 0.06, g = 0.05, b = 0.04, a = 0.96 },
        cardBorder   = { r = 0.28, g = 0.32, b = 0.40, a = 1.00 },
        border       = { r = 0.28, g = 0.32, b = 0.40, a = 1.00 },
        borderGold   = { r = 0.70, g = 0.55, b = 0.20, a = 1.00 },
        titleText    = { r = 0.95, g = 0.80, b = 0.45 },
        headerText   = { r = 0.90, g = 0.75, b = 0.40 },
        bodyText     = { r = 0.90, g = 0.86, b = 0.78 },
        mutedText    = { r = 0.65, g = 0.75, b = 0.85 },
        summaryText  = { r = 0.95, g = 0.85, b = 0.55 },
        accentText   = { r = 0.83, g = 0.66, b = 0.35 },
        highlightHex = "ffd100", -- Radiant Gold for dark contrast
        notesBg      = { r = 0.04, g = 0.04, b = 0.05, a = 0.95 },
        notesBorder  = { r = 0.40, g = 0.35, b = 0.25, a = 0.80 },
        notesText    = { r = 0.90, g = 0.88, b = 0.82 },
        clueBg       = { r = 0.08, g = 0.09, b = 0.12, a = 0.85 },
        clueBorder   = { r = 0.70, g = 0.55, b = 0.20, a = 0.85 },
        clueTitle    = { r = 0.95, g = 0.92, b = 0.85 },
        clueMeta     = { r = 0.65, g = 0.70, b = 0.78 },
    },
}
