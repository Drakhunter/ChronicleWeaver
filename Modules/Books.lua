-- =========================================================================
-- Modules/Books.lua
-- Multi-page book, scroll & plaque harvester. Pages are stored in
-- ChronicleWeaverDB.books and rebuilt into Codex entries on every login.
-- =========================================================================
local _, ns = ...
local L = ns.L

local MIN_KEYWORD_LENGTH = 4

--- Builds a case-insensitive Lua pattern that matches `text` literally.
local function CaseInsensitivePattern(text)
    local escaped = text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%...]", "%%%0")
    return (escaped:gsub("%a", function(c)
        return "[" .. c:lower() .. c:upper() .. "]"
    end))
end

--- Highlights names of other Codex entries inside `rawText`.
--- @return string wovenText
--- @return string[] relatedKeys
function ns.WeaveTextConnections(rawText)
    if type(rawText) ~= "string" or ns.IsSecret(rawText) then return "", {} end

    local woven = rawText
    local related = {}

    for _, entry in ipairs(ns.LoreEntries) do
        local keyword = entry.triggerValue
        if entry.category ~= "Book" and type(keyword) == "string" and #keyword >= MIN_KEYWORD_LENGTH then
            local count
            woven, count = woven:gsub(CaseInsensitivePattern(keyword), function(match)
                return ns.Colorize(ns.COLORS.highlight, "[" .. match .. "]")
            end)
            if count > 0 then
                related[#related + 1] = entry.key
            end
        end
    end

    return woven, related
end

local function FormatLocation(book)
    local loc = book.zone or L.UNKNOWN_ZONE
    if book.subzone and book.subzone ~= "" then
        loc = loc .. " (" .. book.subzone .. ")"
    end
    if (book.x or 0) > 0 then
        loc = loc .. L.BOOK_COORDS:format(book.x * 100, book.y * 100)
    end
    return loc
end

--- Converts a saved book record into a Codex entry.
function ns.RegisterSavedBookInCodex(bookKey, book, silent)
    local pages = {}
    for p = 1, book.maxPage or 1 do
        if book.pages[p] then
            pages[#pages + 1] = ns.Colorize(ns.COLORS.gold, L.BOOK_PAGE_HEADER:format(p)) .. "\n" .. book.pages[p]
        end
    end

    local story, related = ns.WeaveTextConnections(table.concat(pages, "\n\n"))

    ns.AddOrReplaceEntry({
        key = bookKey,
        category = "Book",
        triggerType = "BOOK",
        triggerValue = book.title,
        title = book.title,
        era = L.BOOK_ERA:format(book.pageCount or 1),
        summary = L.BOOK_FOUND_IN:format(FormatLocation(book)),
        story = story,
        related = related,
        mapID = book.mapID,
        x = book.x,
        y = book.y,
    }, silent)
end

--- @return number|nil mapID, number x, number y
local function GetPlayerMapPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or ns.IsSecret(mapID) then return nil, 0, 0 end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos or ns.IsSecret(pos) then return mapID, 0, 0 end

    local x, y = pos:GetXY()
    return mapID, x, y
end

ns.RegisterEvent("ITEM_TEXT_READY", function()
    local title = ns.SafeString(ItemTextGetItem())
    local pageText = ns.SafeString(ItemTextGetText())
    local pageNum = ItemTextGetPage()
    if not title or not pageText or ns.IsSecret(pageNum) then return end
    pageNum = pageNum or 1

    local bookKey = "book:" .. title
    local record = ns.db.books[bookKey]
    if not record then
        local mapID, x, y = GetPlayerMapPosition()
        record = {
            title = title,
            zone = ns.SafeString(GetRealZoneText(), L.UNKNOWN_ZONE),
            subzone = ns.SafeString(GetSubZoneText(), ""),
            mapID = mapID,
            x = x,
            y = y,
            pages = {},
            maxPage = 1,
            pageCount = 0,
        }
        ns.db.books[bookKey] = record
    end

    if record.pages[pageNum] == pageText then return end -- re-reading a known page

    if not record.pages[pageNum] then
        record.pageCount = record.pageCount + 1
    end
    record.pages[pageNum] = pageText
    record.maxPage = math.max(record.maxPage or 1, pageNum)

    ns.RegisterSavedBookInCodex(bookKey, record)
    ns.UnlockEntry(bookKey)
end)

-- Rebuild harvested books into the Codex (runs after BuildLoreIndex, see TOC order)
ns.OnAddonLoaded(function()
    for bookKey, book in pairs(ns.db.books) do
        ns.RegisterSavedBookInCodex(bookKey, book, true)
    end
end)
