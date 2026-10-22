# ChronicleWeaver — Step-by-Step Antigravity Prompts

---

## PROMPT 1.1: Scaffold Folder Structure, `.toc`, and `Core/` Modules
> **Task (Step 1.1):** Refactor ChronicleWeaver into our modular multi-folder architecture and create `ChronicleWeaver.toc`, `Core/Constants.lua`, `Core/Utils.lua`, and `Core/Init.lua`.
> 
> **Requirements:**
> 1. **`ChronicleWeaver.toc`:**
>    - Set `## Interface: 16001`, `## SavedVariables: ChronicleWeaverDB`, and native Minimap Addon Compartment functions.
>    - List all files in exact load order across `Core/`, `Data/`, `Engine/`, and `UI/`.
> 2. **`Core/Constants.lua`:**
>    - Define `ns.CategoryIcons` using real built-in WoW textures (e.g., `Zone = "Interface\\Icons\\INV_Misc_Map_01"`, `Dungeon = "Interface\\Icons\\INV_Misc_Head_Dragon_01"`, `NPC = "Interface\\Icons\\INV_Misc_Head_Human_01"`, `Relic = "Interface\\Icons\\INV_Misc_Gem_Variety_01"`, `Book = "Interface\\Icons\\INV_Misc_Book_09"`, `Quest = "Interface\\Icons\\INV_Misc_Note_01"`, `Dossier = "Interface\\Icons\\INV_Misc_Spyglass_02"`).
>    - Define `ns.CategoryTags` using pure ASCII color-coded tags (`[Z]`, `[D]`, `[N]`, `[R]`, `[B]`, `[Q]`, `[!]`) with zero Unicode characters so `FRIZQT__.TTF` never renders `[▯]`.
>    - Define `ns.MediaPath = "Interface\\AddOns\\" .. addonName .. "\\Media\\"` and color/theme palettes for `"DARK"` and `"PARCHMENT"` modes.
> 3. **`Core/Utils.lua`:**
>    - Implement `ns.IsSecret(val)` and `ns.SafeString(val, fallback)`.
>    - Implement `ns.GetPlayerLocationData()` returning `zone, subzone, mapID, x, y` safely.
>    - Implement `ns.PinEntryToMap(entryKey)` using `UiMapPoint.CreateFromCoordinates` and `C_SuperTrack.SetSuperTrackedUserWaypoint(true)`.
>    - Implement `ns.ToggleFavorite(entryKey)` and `ns.DeleteSavedEntry(entryKey)` (which removes a saved Book, Quest, Relic, or Gossip entry from `ns.db`, `ns.LoreByKey`, and `ns.LoreEntries`, then rebuilds weaves and refreshes the UI).
> 4. **`Core/Init.lua`:**
>    - Set up the event bus (`ns.RegisterEvent`), initialize `ChronicleWeaverDB` inside `ADDON_LOADED` (with tables for `discovered`, `favorites`, `notes`, `books`, `quests`, `items`, `gossip`, `theme = "PARCHMENT"`, `groupByZone = false`), and register `/cw` slash commands and Minimap Compartment handlers.

---

## PROMPT 1.2: Create Modular `Data/` Files & `IndexBuilder.lua`
> **Task (Step 1.2):** Create `Data/Lore_Classic.lua`, `Data/Lore_Forever.lua`, `Data/Lore_Topics.lua`, and `Data/IndexBuilder.lua`.
> 
> **Requirements:**
> 1. **`Data/Lore_Classic.lua` & `Data/Lore_Forever.lua`:**
>    - Populate `ns.RawLoreClassic` and `ns.RawLoreForever` with curated Zone, Dungeon, NPC, and Relic entries (including icon paths, zone names, and summaries for Ironforge, Hall of Thanes, Ruins of Lordaeron, Zephras Isle, Faldrim Anvilmar, Durgen Dirgehammer, Edwin VanCleef, Arugal, and the Hearthstone).
> 2. **`Data/Lore_Topics.lua` (Dynamic Evidence Board Topics):**
>    - Create `ns.RawLoreTopics` containing at least 5 rich Topic Dossiers that automatically cluster the player's harvested quests, books, and NPCs by keywords:
>      - `"dossier:ThreeHammers"` (*The War of the Three Hammers & Old Ironforge* — keywords: `{"Ironforge", "Anvilmar", "Bronzebeard", "Dark Iron", "Thanes", "Dirgehammer", "Khaz Modan"}`)
>      - `"dossier:DefiasConspiracy"` (*The Stonemasons & The Defias Brotherhood* — keywords: `{"VanCleef", "Defias", "Stonemason", "Westfall", "Deadmines", "Stormwind", "Prestor"}`)
>      - `"dossier:SilverpineCurse"` (*Arugal, the Worgen & The Fall of Lordaeron* — keywords: `{"Arugal", "Shadowfang", "Worgen", "Pyrewood", "Gilneas", "Sylvanas", "Deathstalker", "Lordaeron"}`)
>      - `"dossier:BarrensFrontier"` (*Strife Across the Northern Barrens* — keywords: `{"Crossroads", "Oasis", "Kolkar", "Centaur", "Harpy", "Raptor", "Ratchet", "Southsea", "Wailing Caverns"}`)
>      - `"dossier:SkyborneMysteries"` (*Zephras Isle & The Elemental Winds* — keywords: `{"Zephras", "Skyborne", "Windshaper", "Elemental", "Tempest"}`)
> 3. **`Data/IndexBuilder.lua`:**
>    - Implement `ns.UpsertRuntimeEntry(entryObj)` and `ns.BuildLoreIndex()` to merge `RawLoreClassic`, `RawLoreForever`, and `RawLoreTopics` into `ns.LoreEntries`, `ns.LoreByKey`, `ns.LoreByZone`, `ns.LoreByNPC`, and `ns.LoreByItem`.
>    - Hydrate all saved records from `ns.db.books`, `ns.db.quests`, `ns.db.items`, and `ns.db.gossip`.

---

## PROMPT 2.1: Build `Engine/WeaveEngine.lua` (Auto-Highlighter, Backlinks & Topic Clustering)
> **Task (Step 2.1):** Create `Engine/WeaveEngine.lua` to automatically connect harvested Books, Quests, Relics, NPCs, and Topic Dossiers.
> 
> **Requirements:**
> 1. **`ns.WeaveTextConnections(rawText)`:**
>    - Safely guard `rawText` with `ns.IsSecret`.
>    - Scan `rawText` for entity names in `ns.LoreEntries` and topic keywords in `ns.RawLoreTopics`.
>    - Case-insensitively highlight matched entity names in gold (`|cffffd100[%1]|r`) and return `wovenText, matchedKeys`.
> 2. **`ns.RebuildLoreWeb()`:**
>    - Build **bi-directional backlinks** (`ns.Backlinks[entryKey] = { ... }`): whenever Entry A links to Entry B in `A.related`, automatically register Entry A inside `ns.Backlinks[B.key]` so viewing an NPC or Zone shows every Book and Quest that mentions it!
>    - Build **Topic Dossier Clusters** (`ns.DossierClues[dossierKey] = { ... }`): scan all entries in `ns.LoreEntries` (especially harvested Books, Quests, Relics, and NPCs) against each Dossier's `keywords` list. Attach all matching entry keys to that Dossier's `related` / `clues` list so the Dossier fills up automatically as the player explores Azeroth!

---

## PROMPT 2.2: Build `Engine/Scanner_World.lua` & `Engine/Scanner_Books.lua`
> **Task (Steps 2.2 & 2.3):** Create `Engine/Scanner_World.lua` and `Engine/Scanner_Books.lua`.
> 
> **Requirements:**
> 1. **`Engine/Scanner_World.lua`:**
>    - Implement Zone/Subzone unlock scanning, Target NPC unlock scanning (guarded with `ns.IsSecret`), and `BAG_UPDATE_DELAYED` bag scanning.
>    - Hook `TooltipDataProcessor` for Units and Items. On Item tooltips, dynamically harvest any item with quoted flavor text (`"^\"(.+)\"$"` of length >= 16), saving its `itemID`, `name`, `icon` (`C_Item.GetItemIconByID(itemID)`), `flavorText`, and coordinates into `ns.db.items`.
> 2. **`Engine/Scanner_Books.lua`:**
>    - Listen to `ITEM_TEXT_READY`, capturing `ItemTextGetItem()`, `ItemTextGetText()`, and `ItemTextGetPage()` into `ns.db.books[bookKey]` without ever overwriting other pages.
>    - Create a small, clean HUD badge anchored to the top of Blizzard's `ItemTextFrame` (`ChronicleWeaverBookBadge`) that displays `"|cff4cd964✓ ChronicleWeaver: Page X Archived (Y Pages Total)|r"` whenever the player reads an in-game book or plaque.

---

## PROMPT 2.3: Build `Engine/Scanner_Quests.lua` (Pure Lore Stories Only + Gossip Button)
> **Task (Step 2.4):** Create `Engine/Scanner_Quests.lua` to harvest pure quest narratives and optional NPC gossip.
> 
> **Requirements:**
> 1. **Pure Story Quest Rule (No Kill Counters!):**
>    - Never capture objective kill counters (`10/12 Raptor Head`) or `QUEST_PROGRESS` text.
>    - On `QUEST_DETAIL`, capture `GetTitleText()`, `GetQuestText()` (the lore story), `UnitName("questnpc") or UnitName("target")`, and location data.
>    - On `QUEST_COMPLETE`, capture `GetRewardText()` (the turn-in resolution lore) and append it under a `"Resolution"` section.
> 2. **Full Quest Log Story Backfill:**
>    - Implement `ns.ScanActiveQuestLog()` and run it on `PLAYER_ENTERING_WORLD` (after a short `C_Timer.After(1, ...)` delay).
>    - Save the current selection via `GetQuestLogSelection()`, loop through `GetNumQuestLogEntries()`, select each non-header quest with `SelectQuestLogEntry(i)`, and call `local questDescription, questObjectives = GetQuestLogQuestText()`.
>    - Save `questDescription` (and `questObjectives` ONLY if it is narrative prose, never leaderboard counters) into `ns.db.quests[questKey]`, overwriting any old incomplete records that lacked a `description`. Restore the original quest log selection when done.
> 3. **1-Click Gossip Lore Archiver:**
>    - Attach a compact `"📜 Archive Lore"` button to Blizzard's `GossipFrame` (when `GossipFrame` exists). Clicking it captures `UnitName("npc") or UnitName("target")`, `C_GossipInfo.GetText()`, and location coordinates into `ns.db.gossip`, weaves connections, and unlocks the entry!

---

## PROMPT 3.1: Build `UI/ThemeEngine.lua`, `UI/ToastBanner.lua`, `UI/MainFrame.lua` & `UI/SidebarList.lua`
> **Task (Steps 3.1 & 3.2):** Create the core UI shell, Dual-Theme switcher, and bug-free Sidebar List.
> 
> **Requirements:**
> 1. **`UI/ThemeEngine.lua`:**
>    - Provide `ns.ApplyTheme(readerFrame, ...)` supporting `"PARCHMENT"` (warm ivory/parchment background using native WoW `QuestBG` / `UI-Background-Marble` textures with warm bronze borders and amber headers) and `"DARK"` (Midnight Obsidian slate with soft ivory text).
> 2. **`UI/MainFrame.lua`:**
>    - Create the `980x660` resizable main window (`ChronicleWeaverMainFrame`) with a bottom-right resize grip, a **"Theme: Parchment/Dark"** toggle button, a **"Spoilers: Hidden/Shown"** toggle button, 8 category tabs (`ALL`, `Zone`, `Dungeon`, `NPC`, `Relic`, `Book`, `Quest`, `Dossier`), and a live search box.
> 3. **`UI/SidebarList.lua` (Bug-Free Scrolling & Single-Line Rows):**
>    - Create `21` reusable row buttons (`244x22`) inside `listPanel`.
>    - **Strict 1-Line Fix:** On every `btn.text`, enforce `SetWordWrap(false)`, `SetNonSpaceWrap(false)`, `SetMaxLines(1)`, and `SetHeight(16)` so long titles never wrap onto 2 lines.
>    - **Inline Icons & Favorites:** Render a 14×14 texture icon (`|TiconPath:14:14:0:0|t`) for each entry's category or item icon, plus a gold star `|cffffd100★|r` if `ns.db.favorites[item.key]` is true. Right-clicking a row toggles Favorite status and sorts Favorites to the top!
>    - **Fixed Scrollbar & Mouse-Wheel:** Add a visible vertical `Slider` (`listScrollBar`) with a gold thumb on the right edge of `listPanel`. Forward `OnMouseWheel` on both `listPanel` AND every row button to `ScrollListByDelta(delta)`. NEVER clamp or snap `listScrollOffset` to `selectedKey`—the user must be able to scroll freely from row 1 to the end of the list!

---

## PROMPT 3.2: Build `UI/ReaderView.lua` & `UI/DossierView.lua`
> **Task (Steps 3.3 & 3.4):** Create the right-hand Tome Reader and the Dossier Evidence Board view.
> 
> **Requirements:**
> 1. **`UI/ReaderView.lua`:**
>    - **Dossier Header Card:** Add a framed `44x44` icon portrait in the top-left of `readerPanel` showing the entry's specific icon (or category icon), next to the large `entryHeading`, `entryMeta` (Category • Zone • Discovery Status), and `entrySummary`.
>    - **Action Buttons:** Include `"Pin to Map"` (shown when `entry.mapID` & `entry.x > 0`) and `"Delete"` (with confirmation popup, shown for harvested Books, Quests, Relics, or Gossip).
>    - **Scrollable Story Area:** Use a smooth `UIPanelScrollFrameTemplate` containing `entryStory` with generous line spacing (`SetSpacing(4)`).
>    - **Interactive Connections & Backlinks Bar:** Above the Field Notes box, render up to 6 clickable pill buttons combining `entry.related` AND `ns.Backlinks[entry.key]` (*"Connected & Mentioned In"*), allowing 1-click jumping between a Boss, the Quests about them, and the Books that mention them!
> 2. **`UI/DossierView.lua` (Integrated or Swapped when `entry.category == "Dossier"`):**
>    - When viewing a `Dossier` entry, display its overarching lore summary at the top, followed by an **"Uncovered Evidence & Clues (X Found)"** section that lists every matching Quest, Book, Relic, Dungeon, and NPC dynamically linked by `WeaveEngine`, allowing 1-click navigation to each piece of evidence!