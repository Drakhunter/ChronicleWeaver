-- =========================================================================
-- Engine/Scanner_Quests.lua
-- Pure-story quest harvester (Description + Resolution) & 1-click Gossip button.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

-- -------------------------------------------------------------------------
-- Helper: Objective Prose Validator (Pure Lore Story Rule - No Kill Counters!)
-- Strictly rejects leaderboard counters like "10/12 Raptor Head" or "Slain: 0/5"
-- -------------------------------------------------------------------------
local function IsNarrativeProse(text)
    if not text or type(text) ~= "string" or #text < 10 then
        return false
    end
    -- Filter out lines with fractional counters (e.g. 5/10, 0/1, 12 / 12)
    if text:match("%d+%s*/%s*%d+") then
        return false
    end
    -- Filter out typical leaderboard counter keywords
    local ltext = text:lower()
    if ltext:match("slain%s*:") or ltext:match("killed%s*:") or ltext:match("collected%s*:") or ltext:match("destroyed%s*:") then
        return false
    end
    -- Must have at least a few words (narrative sentences)
    local wordCount = select(2, text:gsub("%S+", ""))
    return wordCount >= 5
end

-- -------------------------------------------------------------------------
-- 1. Pure Story Quest Event Harvester (QUEST_DETAIL & QUEST_COMPLETE)
-- -------------------------------------------------------------------------
local function OnQuestDetail()
    if not ns.db then return end
    ns.db.quests = ns.db.quests or {}

    local rawTitle = GetTitleText and GetTitleText()
    local title = ns.SafeString(rawTitle, nil)
    if not title or title == "" then return end

    local rawQuestText = GetQuestText and GetQuestText()
    local questText = ns.SafeString(rawQuestText, nil)
    if not questText or questText == "" then return end

    local rawGiver = (UnitExists("questnpc") and UnitName("questnpc"))
        or (UnitExists("target") and UnitName("target"))
    local giver = ns.SafeString(rawGiver, nil)

    local zone, subzone, mapID, x, y = ns.GetPlayerLocationData()
    local questKey = "quest:" .. title
    local playerKey = ns.GetPlayerKey()

    local record = ns.db.quests[questKey] or {
        title = title,
        giver = giver,
        zone = zone,
        subzone = subzone,
        mapID = mapID,
        x = x,
        y = y,
        character = playerKey,
        characters = {},
        faction = ns.GetPlayerFaction(),
    }

    record.title = title
    if giver and giver ~= "" then record.giver = giver end
    record.description = questText
    record.zone = zone
    record.subzone = subzone
    record.characters = record.characters or {}
    if record.character then record.characters[record.character] = true end
    record.characters[playerKey] = true
    if x and x > 0 then
        record.mapID = mapID
        record.x = x
        record.y = y
    end

    ns.db.quests[questKey] = record

    if ns.RegisterSavedQuestInCodex then
        ns.RegisterSavedQuestInCodex(questKey, record)
    end
    if ns.RebuildLoreWeb then
        ns.RebuildLoreWeb()
    end
    ns.UnlockEntry(questKey)
end

local function OnQuestComplete()
    if not ns.db then return end
    ns.db.quests = ns.db.quests or {}

    local rawTitle = GetTitleText and GetTitleText()
    local title = ns.SafeString(rawTitle, nil)
    if not title or title == "" then return end

    local rawRewardText = GetRewardText and GetRewardText()
    local rewardText = ns.SafeString(rawRewardText, nil)
    if not rewardText or rewardText == "" then return end

    local questKey = "quest:" .. title
    local record = ns.db.quests[questKey]
    local playerKey = ns.GetPlayerKey()

    if not record then
        local rawGiver = (UnitExists("questnpc") and UnitName("questnpc"))
            or (UnitExists("target") and UnitName("target"))
        local giver = ns.SafeString(rawGiver, nil)
        local zone, subzone, mapID, x, y = ns.GetPlayerLocationData()

        record = {
            title = title,
            giver = giver,
            zone = zone,
            subzone = subzone,
            mapID = mapID,
            x = x,
            y = y,
            character = playerKey,
            characters = {},
            faction = ns.GetPlayerFaction(),
        }
    end

    record.characters = record.characters or {}
    if record.character then record.characters[record.character] = true end
    record.characters[playerKey] = true

    local isNewResolution = not record.resolution or record.resolution ~= rewardText
    record.resolution = rewardText
    ns.db.quests[questKey] = record

    if ns.RegisterSavedQuestInCodex then
        ns.RegisterSavedQuestInCodex(questKey, record)
    end
    if ns.RebuildLoreWeb then
        ns.RebuildLoreWeb()
    end
    ns.UnlockEntry(questKey)

    if isNewResolution then
        ns.Print(string.format("Recorded completion resolution for quest: |cffffd100%s|r", title))
    end
end

ns.RegisterEvent("QUEST_DETAIL", OnQuestDetail)
ns.RegisterEvent("QUEST_COMPLETE", OnQuestComplete)

-- -------------------------------------------------------------------------
-- 2. Auto-Heal Duplicate Quest Descriptions & Active Quest Log Scanner
-- -------------------------------------------------------------------------
function ns.SanitizeDuplicateQuests()
    if not ns.db or type(ns.db.quests) ~= "table" then return end

    local descCounts = {}
    local objCounts = {}
    for _, rec in pairs(ns.db.quests) do
        if type(rec) == "table" then
            if rec.description and rec.description ~= "" then
                descCounts[rec.description] = (descCounts[rec.description] or 0) + 1
            end
            if rec.objectiveProse and rec.objectiveProse ~= "" then
                objCounts[rec.objectiveProse] = (objCounts[rec.objectiveProse] or 0) + 1
            end
        end
    end

    for qKey, rec in pairs(ns.db.quests) do
        if type(rec) == "table" then
            if rec.description and (descCounts[rec.description] or 0) > 1 then
                rec.description = nil
            end
            if rec.objectiveProse and (objCounts[rec.objectiveProse] or 0) > 1 then
                rec.objectiveProse = nil
            end
            if ns.RegisterSavedQuestInCodex then
                ns.RegisterSavedQuestInCodex(qKey, rec)
            end
        end
    end
end

function ns.ScanActiveQuestLog()
    if not ns.db then return end
    ns.db.quests = ns.db.quests or {}
    ns.SanitizeDuplicateQuests()

    local numEntries = 0
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        numEntries = C_QuestLog.GetNumQuestLogEntries() or 0
    elseif GetNumQuestLogEntries then
        numEntries = GetNumQuestLogEntries() or 0
    end

    if not numEntries or numEntries <= 0 or ns.IsSecret(numEntries) then return end

    local prevSelection = (GetQuestLogSelection and GetQuestLogSelection()) or 0
    local prevQuestID = (C_QuestLog and C_QuestLog.GetSelectedQuest and C_QuestLog.GetSelectedQuest()) or nil
    local playerZone = ns.GetPlayerLocationData()
    local currentHeader = playerZone
    local playerKey = ns.GetPlayerKey()

    local seenDescriptions = {}

    for i = 1, numEntries do
        local title, questID, isHeader = nil, nil, false

        if C_QuestLog and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(i)
            if info and not ns.IsSecret(info) then
                title = ns.SafeString(info.title, nil)
                questID = info.questID
                isHeader = info.isHeader
                if isHeader and title and title ~= "" then
                    currentHeader = title
                end
            end
        elseif GetQuestLogTitle then
            local qTitle, _, _, qIsHeader, _, _, _, qID = GetQuestLogTitle(i)
            title = ns.SafeString(qTitle, nil)
            questID = qID
            isHeader = qIsHeader
            if isHeader and title and title ~= "" then
                currentHeader = title
            end
        end

        if not isHeader and title and title ~= "" then
            local questKey = "quest:" .. title

            if C_QuestLog and C_QuestLog.SetSelectedQuest and questID then
                C_QuestLog.SetSelectedQuest(questID)
            end
            if SelectQuestLogEntry then
                SelectQuestLogEntry(i)
            end

            local questDescription = nil
            local questObjectives = nil

            if C_QuestLog and C_QuestLog.GetQuestDescription and questID then
                questDescription = ns.SafeString(C_QuestLog.GetQuestDescription(questID), nil)
            end

            if GetQuestLogQuestText then
                local qDesc, qObj = GetQuestLogQuestText()
                if not questDescription or questDescription == "" then
                    questDescription = ns.SafeString(qDesc, nil)
                end
                questObjectives = ns.SafeString(qObj, nil)
            end

            -- Guard against stale selection returning identical description across different quests
            if questDescription and questDescription ~= "" then
                if seenDescriptions[questDescription] and seenDescriptions[questDescription] ~= questKey then
                    questDescription = nil
                else
                    seenDescriptions[questDescription] = questKey
                end
            end

            local narrativeObjective = nil
            if questObjectives and IsNarrativeProse(questObjectives) then
                narrativeObjective = questObjectives
            end

            local record = ns.db.quests[questKey] or {
                title = title,
                questID = questID,
                zone = currentHeader or playerZone,
                character = playerKey,
                characters = {},
                faction = ns.GetPlayerFaction(),
            }

            record.title = title
            if questID then record.questID = questID end
            record.zone = currentHeader or record.zone or playerZone
            record.characters = record.characters or {}
            if record.character then record.characters[record.character] = true end
            record.characters[playerKey] = true

            -- Strictly overwrite/backfill narrative description
            if questDescription and questDescription ~= "" then
                record.description = questDescription
            end
            if narrativeObjective and narrativeObjective ~= "" then
                record.objectiveProse = narrativeObjective
            end

            -- Ensure leaderboard counters are wiped if old version saved them
            record.objectiveText = nil

            ns.db.quests[questKey] = record

            if ns.RegisterSavedQuestInCodex then
                ns.RegisterSavedQuestInCodex(questKey, record)
            end
            ns.UnlockEntry(questKey)
        end
    end

    if prevQuestID and C_QuestLog and C_QuestLog.SetSelectedQuest then
        C_QuestLog.SetSelectedQuest(prevQuestID)
    end
    if prevSelection and prevSelection > 0 and SelectQuestLogEntry then
        SelectQuestLogEntry(prevSelection)
    end

    if ns.RebuildLoreWeb then
        ns.RebuildLoreWeb()
    end
end

-- Alias for slash command (/cw scan or /cw quests)
ns.ScanQuestLog = ns.ScanActiveQuestLog

ns.RegisterEvent("QUEST_ACCEPTED", function()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, ns.ScanActiveQuestLog)
    end
end)

ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
    if C_Timer and C_Timer.After then
        C_Timer.After(1.0, function()
            if ns.ScanActiveQuestLog then
                ns.ScanActiveQuestLog()
            end
        end)
    end
end)

-- -------------------------------------------------------------------------
-- 3. 1-Click Gossip Lore Archiver Button on GossipFrame
-- -------------------------------------------------------------------------
local function CreateGossipArchiveButton()
    if ChronicleWeaverGossipButton or not GossipFrame then
        return ChronicleWeaverGossipButton
    end

    local btn = CreateFrame("Button", "ChronicleWeaverGossipButton", GossipFrame, "BackdropTemplate")
    btn:SetSize(120, 22)
    btn:SetPoint("TOPRIGHT", GossipFrame, "TOPRIGHT", -26, -34)
    btn:SetFrameLevel((GossipFrame:GetFrameLevel() or 10) + 15)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    btn:SetBackdropColor(0.08, 0.09, 0.12, 0.94)
    btn:SetBackdropBorderColor(0.75, 0.58, 0.18, 1.0)

    local fontString = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontString:SetPoint("CENTER", btn, "CENTER", 0, 0)
    fontString:SetText("|cffd4a85a[+] Archive Lore|r")
    btn.text = fontString

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1.0, 0.85, 0.20, 1.0)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("ChronicleWeaver Gossip Archiver", 1, 0.82, 0.45)
        GameTooltip:AddLine("Click to record this NPC's dialogue and story into your personal field journal.", 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.75, 0.58, 0.18, 1.0)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(self)
        if not ns.db then return end
        ns.db.gossip = ns.db.gossip or {}

        local rawNpc = (UnitExists("npc") and UnitName("npc"))
            or (UnitExists("target") and UnitName("target"))
            or (GossipFrameTitleText and GossipFrameTitleText.GetText and GossipFrameTitleText:GetText())
        local npcName = ns.SafeString(rawNpc, "Mysterious Traveler")

        local rawText = (C_GossipInfo and C_GossipInfo.GetText and C_GossipInfo.GetText())
            or (GetGossipText and GetGossipText())
        local gossipText = ns.SafeString(rawText, nil)

        if not gossipText or #gossipText < 10 then
            ns.Print("No story dialogue available to archive.")
            return
        end

        local zone, subzone, mapID, x, y = ns.GetPlayerLocationData()
        local gossipKey = "gossip:" .. npcName
        local playerKey = ns.GetPlayerKey()
        local existing = ns.db.gossip[gossipKey]
        local chars = (existing and existing.characters) or {}
        if existing and existing.character then chars[existing.character] = true end
        chars[playerKey] = true

        local record = {
            title = "Dialogue: " .. npcName,
            npc = npcName,
            text = gossipText,
            zone = zone,
            subzone = subzone,
            mapID = mapID,
            x = x,
            y = y,
            character = (existing and existing.character) or playerKey,
            characters = chars,
            faction = ns.GetPlayerFaction(),
            time = time(),
        }

        ns.db.gossip[gossipKey] = record

        if ns.RegisterSavedGossipInCodex then
            ns.RegisterSavedGossipInCodex(gossipKey, record)
        end
        if ns.RebuildLoreWeb then
            ns.RebuildLoreWeb()
        end
        ns.UnlockEntry(gossipKey)

        ns.Print(string.format("Archived story dialogue from |cffffd100%s|r!", npcName))

        -- Visual feedback on button
        self.text:SetText("|cff4cd964[OK] Archived!|r")
        if C_Timer and C_Timer.After then
            C_Timer.After(2.0, function()
                if self and self.text then
                    self.text:SetText("|cffd4a85a[+] Archive Lore|r")
                end
            end)
        end
    end)

    return btn
end

local function OnGossipShow()
    local btn = CreateGossipArchiveButton()
    if btn then
        btn.text:SetText("|cffd4a85a[+] Archive Lore|r")
        btn:Show()
    end
end

ns.RegisterEvent("GOSSIP_SHOW", OnGossipShow)
if GossipFrame then
    GossipFrame:HookScript("OnShow", OnGossipShow)
end
