-- =========================================================================
-- Engine/WeaveEngine.lua
-- Bi-directional backlinks, keyword weaving & topic dossier clustering.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

ns.Backlinks = {}
ns.DossierClues = {}

-- -------------------------------------------------------------------------
-- Helper: Case-Insensitive Pattern Generator & Escaper
-- -------------------------------------------------------------------------
local function MakeCaseInsensitivePattern(pattern)
    local p = pattern:gsub("(%%?)(.)", function(percent, letter)
        if percent ~= "" then
            return percent .. letter
        elseif letter:match("%a") then
            return string.format("[%s%s]", letter:lower(), letter:upper())
        elseif letter:match("[%(%)%.%%%+%-%*%?%[%]%^%$]") then
            return "%" .. letter
        else
            return letter
        end
    end)
    return p
end

local function MatchesKeywordInText(text, keyword)
    if not text or type(text) ~= "string" or not keyword or #keyword < 3 then
        return false
    end
    local escapedKw = keyword:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"):lower()
    local pat = "%f[%a]" .. escapedKw .. "%f[%A]"
    return text:lower():match(pat) ~= nil
end

local function EntryMatchesDossierZones(dossierZones, entryZone)
    if not dossierZones or #dossierZones == 0 then return true end
    if not entryZone or entryZone == "" or entryZone == "Unknown" or entryZone == "Azeroth" then
        return true
    end
    local lEntryZone = entryZone:lower()
    for _, z in ipairs(dossierZones) do
        local lz = z:lower()
        if lEntryZone == lz or lEntryZone:find(lz, 1, true) or lz:find(lEntryZone, 1, true) then
            return true
        end
    end
    return false
end

-- -------------------------------------------------------------------------
-- Build Weavable Candidates List
-- -------------------------------------------------------------------------
local cachedCandidates = nil

local function BuildWeavableCandidates()
    if cachedCandidates then return cachedCandidates end

    local list = {}
    local seen = {}

    -- 1. Entity names and triggers in ns.LoreEntries
    if ns.LoreEntries then
        for _, entry in ipairs(ns.LoreEntries) do
            if entry.category ~= "Dossier" then
                if entry.triggerValue and type(entry.triggerValue) == "string" and #entry.triggerValue >= 3 then
                    local val = entry.triggerValue
                    local lval = val:lower()
                    if not seen[lval] then
                        seen[lval] = true
                        table.insert(list, { phrase = val, key = entry.key })
                    end
                end

                if entry.title and type(entry.title) == "string" and #entry.title >= 3 then
                    -- Strip level indicators e.g. " (Levels 13-18)" and sub-clauses
                    local cleanTitle = entry.title:gsub("%s*%b()", ""):gsub("%s*:%s*.*", ""):gsub("^%s*(.-)%s*$", "%1")
                    local ltitle = cleanTitle:lower()
                    if #cleanTitle >= 3 and not seen[ltitle] then
                        seen[ltitle] = true
                        table.insert(list, { phrase = cleanTitle, key = entry.key })
                    end
                end
            end
        end
    end

    -- 2. Topic keywords in ns.RawLoreTopics
    if ns.RawLoreTopics then
        for _, topic in ipairs(ns.RawLoreTopics) do
            if topic.keywords then
                for _, kw in ipairs(topic.keywords) do
                    if type(kw) == "string" and #kw >= 3 then
                        local lkw = kw:lower()
                        if not seen[lkw] then
                            seen[lkw] = true
                            table.insert(list, { phrase = kw, key = topic.key })
                        end
                    end
                end
            end
        end
    end

    -- Sort longest phrases first to prevent substring collisions
    table.sort(list, function(a, b)
        return #a.phrase > #b.phrase
    end)

    cachedCandidates = list
    return cachedCandidates
end

function ns.InvalidateWeaveCache()
    cachedCandidates = nil
end

-- -------------------------------------------------------------------------
-- 1. Weave Text Connections & Case-Insensitive Gold Highlighter
-- -------------------------------------------------------------------------
function ns.WeaveTextConnections(rawText)
    if not rawText or ns.IsSecret(rawText) then
        return "", {}
    end
    if type(rawText) ~= "string" or rawText == "" then
        return tostring(rawText or ""), {}
    end

    local candidates = BuildWeavableCandidates()
    if #candidates == 0 then
        return rawText, {}
    end

    local wovenText = rawText
    local tokens = {}
    local matchedKeys = {}
    local seenKeys = {}

    for _, cand in ipairs(candidates) do
        -- Strict Spoiler-Safe check: only highlight if target entity is unlocked
        local canHighlight = true
        if ns.db and ns.db.spoilerFree == true then
            local targetEntry = ns.LoreByKey and ns.LoreByKey[cand.key]
            if not targetEntry or not (ns.IsEntryUnlocked and ns.IsEntryUnlocked(targetEntry)) then
                canHighlight = false
            end
        end

        if canHighlight then
            local pat = MakeCaseInsensitivePattern(cand.phrase)
            local frontierPat = "%f[%a](" .. pat .. ")%f[%A]"

            if wovenText:match(frontierPat) then
                if not seenKeys[cand.key] then
                    seenKeys[cand.key] = true
                    table.insert(matchedKeys, cand.key)
                end

                wovenText = wovenText:gsub(frontierPat, function(matchedWord)
                    local idx = #tokens + 1
                    tokens[idx] = "|cffffd100[" .. matchedWord .. "]|r"
                    return "\001" .. idx .. "\002"
                end)
            end
        end
    end

    -- Restore tokens from placeholders
    if #tokens > 0 then
        wovenText = wovenText:gsub("\001(%d+)\002", function(idxStr)
            return tokens[tonumber(idxStr)] or ""
        end)
    end

    return wovenText, matchedKeys
end

-- -------------------------------------------------------------------------
-- 2. Rebuild Bi-Directional Backlinks & Topic Dossier Clusters
-- -------------------------------------------------------------------------
function ns.RebuildLoreWeb()
    ns.InvalidateWeaveCache()

    ns.Backlinks = {}
    ns.DossierClues = {}

    if not ns.LoreEntries then return end

    -- 1. Initialize backlink tables for all registered entries
    for _, entry in ipairs(ns.LoreEntries) do
        ns.Backlinks[entry.key] = {}
    end

    -- 2. Bi-directional backlinks from explicit 'related' references
    for _, entry in ipairs(ns.LoreEntries) do
        if entry.related and type(entry.related) == "table" then
            for _, targetKey in ipairs(entry.related) do
                if targetKey and targetKey ~= entry.key then
                    ns.Backlinks[targetKey] = ns.Backlinks[targetKey] or {}
                    local alreadyLinked = false
                    for _, existingKey in ipairs(ns.Backlinks[targetKey]) do
                        if existingKey == entry.key then
                            alreadyLinked = true
                            break
                        end
                    end
                    if not alreadyLinked then
                        table.insert(ns.Backlinks[targetKey], entry.key)
                    end
                end
            end
        end
    end

    -- 3. Topic Dossier Clustering with Strict Zone & Whole-Word Keyword Matching
    local dossiers = {}
    for _, entry in ipairs(ns.LoreEntries) do
        if entry.category == "Dossier" then
            table.insert(dossiers, entry)
        end
    end

    for _, dossier in ipairs(dossiers) do
        local dKey = dossier.key
        ns.DossierClues[dKey] = {}
        dossier.related = dossier.related or {}
        local cluesMap = {}

        -- Seed with existing related keys
        for _, relKey in ipairs(dossier.related) do
            if not cluesMap[relKey] and (not ns.LoreByKey or ns.LoreByKey[relKey]) then
                cluesMap[relKey] = true
                table.insert(ns.DossierClues[dKey], relKey)
            end
        end

        local keywords = dossier.keywords or {}
        local dZones = dossier.zones
        local hasDossierZones = (dZones and #dZones > 0)

        if #keywords > 0 then
            for _, entry in ipairs(ns.LoreEntries) do
                if entry.key ~= dKey and entry.category ~= "Dossier" and not cluesMap[entry.key] then
                    local hasKnownZone = entry.zone and entry.zone ~= "" and entry.zone ~= "Unknown" and entry.zone ~= "Azeroth"
                    local inZone = true
                    if hasDossierZones and hasKnownZone then
                        inZone = EntryMatchesDossierZones(dZones, entry.zone)
                    end

                    local matched = false
                    if inZone then
                        -- Entry's zone matches dossier's zones (or zone is generic):
                        -- scan title, summary, story, npc, and zone using whole-word frontier matching
                        for _, kw in ipairs(keywords) do
                            if MatchesKeywordInText(entry.title, kw)
                                or MatchesKeywordInText(entry.summary, kw)
                                or MatchesKeywordInText(entry.story, kw)
                                or MatchesKeywordInText(entry.npc, kw)
                                or MatchesKeywordInText(entry.zone, kw) then
                                matched = true
                                break
                            end
                        end
                    else
                        -- Candidate entry is known to be in an outside zone:
                        -- ONLY match if candidate title explicitly contains one of the proper-noun keywords!
                        for _, kw in ipairs(keywords) do
                            if MatchesKeywordInText(entry.title, kw) then
                                matched = true
                                break
                            end
                        end
                    end

                    if matched then
                        cluesMap[entry.key] = true
                        table.insert(ns.DossierClues[dKey], entry.key)
                        table.insert(dossier.related, entry.key)
                    end
                end
            end
        end

        -- Ensure bi-directional backlinks point back to the Dossier from each clue
        for _, clueKey in ipairs(ns.DossierClues[dKey]) do
            ns.Backlinks[clueKey] = ns.Backlinks[clueKey] or {}
            local hasDossier = false
            for _, bKey in ipairs(ns.Backlinks[clueKey]) do
                if bKey == dKey then
                    hasDossier = true
                    break
                end
            end
            if not hasDossier then
                table.insert(ns.Backlinks[clueKey], dKey)
            end
        end
    end

    if ns.SendMessage then
        ns.SendMessage("LORE_WEB_REBUILT")
    end
end

-- -------------------------------------------------------------------------
-- Query Helpers
-- -------------------------------------------------------------------------
function ns.GetBacklinks(entryKey)
    return ns.Backlinks[entryKey] or {}
end

function ns.GetDossierClues(dossierKey)
    return ns.DossierClues[dossierKey] or {}
end

function ns.GetConnectedLore(entryKey)
    local entry = ns.LoreByKey and ns.LoreByKey[entryKey]
    local connected = {}
    local seen = { [entryKey] = true }

    if entry and entry.related then
        for _, relKey in ipairs(entry.related) do
            if not seen[relKey] then
                seen[relKey] = true
                table.insert(connected, relKey)
            end
        end
    end

    if ns.Backlinks[entryKey] then
        for _, bKey in ipairs(ns.Backlinks[entryKey]) do
            if not seen[bKey] then
                seen[bKey] = true
                table.insert(connected, bKey)
            end
        end
    end

    return connected
end
