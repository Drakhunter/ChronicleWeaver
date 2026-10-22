-- luacheck configuration for ChronicleWeaver (WoW: Forever, Interface 16001)
std = "lua51"
max_line_length = false
self = false

exclude_files = {
    "dist/**",
    "Docs/**",
    "archive/**",
    "Modules/**",
    "Locales/**",
    "Data/WoWForever_Zones_Dungeons.lua",
    "UI/CodexFrame.lua",
    "UI/Settings.lua",
    "UI/Theme.lua",
    "UI/Toast.lua",
}

ignore = {
    "212/_.*",       -- unused arguments prefixed with underscore
    "212/self",      -- unused self argument in WoW frame script callbacks
    "211/_.*",       -- unused locals prefixed with underscore
    "211/addonName", -- unused addonName vararg in WoW addon files
}

-- Globals the addon defines or references across files
globals = {
    "ChronicleWeaverDB",
    "ChronicleWeaverMainFrame",
    "ChronicleWeaverListScrollBar",
    "ChronicleWeaverReaderPortrait",
    "ChronicleWeaverStoryScrollFrame",
    "ChronicleWeaverBookBadge",
    "ChronicleWeaverGossipButton",
    "ChronicleWeaverToastFrame",
    "SLASH_CHRONICLEWEAVER1",
    "SLASH_CHRONICLEWEAVER2",
    "ChronicleWeaver_OnAddonCompartmentClick",
    "ChronicleWeaver_OnAddonCompartmentEnter",
    "ChronicleWeaver_OnAddonCompartmentLeave",
    "SlashCmdList",
    "UISpecialFrames",
    "StaticPopupDialogs",
}

-- WoW API used by the addon (read-only)
read_globals = {
    -- Lua / WoW extensions
    "strtrim", "tinsert", "time", "unpack",

    -- Frames & UI
    "CreateFrame", "UIParent", "GameTooltip", "GameTooltipTextLeft1",
    "ItemTextFrame", "ItemTextFrameTitleText", "ItemTextPageText",
    "GossipFrame", "GossipFrameTitleText",
    "StaticPopup_Show", "InCombatLockdown",
    "PlaySound", "SOUNDKIT",
    "TooltipDataProcessor", "UiMapPoint",

    -- Namespaced APIs
    "C_AddOns", "C_Container", "C_GossipInfo", "C_Item", "C_Map",
    "C_QuestLog", "C_SuperTrack", "C_Timer", "Enum",

    -- Unit / zone / item / quest / book text
    "UnitExists", "UnitName", "UnitFactionGroup", "GetRealmName",
    "GetRealZoneText", "GetZoneText", "GetSubZoneText",
    "ItemTextGetItem", "ItemTextGetText", "ItemTextGetPage",
    "GetTitleText", "GetQuestText", "GetRewardText", "GetGossipText",
    "GetNumQuestLogEntries", "GetQuestLogSelection", "GetQuestLogTitle",
    "SelectQuestLogEntry", "GetQuestLogQuestText",

    -- Errors & secret values
    "CallErrorHandler", "issecretvalue",
}
