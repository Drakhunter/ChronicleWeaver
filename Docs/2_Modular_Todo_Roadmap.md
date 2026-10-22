# ChronicleWeaver — Modular Component Todo-List

## Phase 1: Multi-Folder Architecture & Core Engine (`Core/` & `Data/`)
- [x] **Step 1.1 (`.toc` & `Core/`):** Create the new folder structure (`Core/`, `Data/`, `Engine/`, `UI/`, `Media/`) and update `ChronicleWeaver.toc` load order. Implement `Core/Constants.lua` (icons, colors, theme palettes), `Core/Utils.lua` (`IsSecret`, `SafeString`, `PinEntryToMap`, `DeleteEntry`), and `Core/Init.lua` (event bus, `ADDON_LOADED`, slash commands, compartment hooks).
- [x] **Step 1.2 (`Data/`):** Split static lore into `Data/Lore_Classic.lua`, `Data/Lore_Forever.lua`, and `Data/Lore_Topics.lua` (dynamic keyword clusters). Build `Data/IndexBuilder.lua` to compile all static tables and hydrate saved Books, Quests, Relics, and Gossip on `ADDON_LOADED`.

## Phase 2: The Weave Engine & Pure-Lore Harvesters (`Engine/`)
- [x] **Step 2.1 (`Engine/WeaveEngine.lua`):** Build the keyword highlighter, bi-directional backlink graph (`ns.Backlinks[key]`), and dynamic Topic Dossier clusterer (`ns.TopicMatches[topicKey]`).
- [x] **Step 2.2 (`Engine/Scanner_World.lua`):** Implement Zone/Subzone scanner, Target NPC scanner, Bag Relic scanner, and Unit/Item Tooltip hooks (including dynamic yellow flavor-text item harvesting with real item icons).
- [x] **Step 2.3 (`Engine/Scanner_Books.lua`):** Implement the multi-page `ITEM_TEXT_READY` harvester with coordinate stamping AND attach a small status badge to Blizzard's `ItemTextFrame` showing which pages have been archived.
- [x] **Step 2.4 (`Engine/Scanner_Quests.lua`):** Implement the **Pure-Story Quest Harvester** (`QUEST_DETAIL`, `QUEST_COMPLETE`, and full `GetQuestLogQuestText()` Quest Log backfill—strictly excluding kill counters and progress text). Add the 1-click **"📜 Archive Dialogue"** button to `GossipFrame`.

## Phase 3: The AAAA Tome UI & Theme Engine (`UI/`)
- [x] **Step 3.1 (`UI/ThemeEngine.lua` & `UI/ToastBanner.lua`):** Build the Dual-Theme manager (*Archivist Parchment* vs. *Midnight Obsidian*), custom `Media/` texture helper, and the animated Discovery Toast banner with sound toggle.
- [x] **Step 3.2 (`UI/MainFrame.lua` & `UI/SidebarList.lua`):** Build the `980x660` resizable shell, category filter bar (`ALL`, `Zone`, `Dungeon`, `NPC`, `Relic`, `Book`, `Quest`, `Dossier`), and the bug-free **Sidebar List** featuring:
  - Un-trapped mouse-wheel scrolling + draggable gold scrollbar `Slider`
  - Strict 1-line title truncation (`SetMaxLines(1)`)
  - Crisp 14×14 inline WoW texture icons (no `[▯]` font boxes)
  - Right-click Favorite (`★`) pinning & optional Zone grouping toggle
- [x] **Step 3.3 (`UI/ReaderView.lua`):** Build the right-hand **Living Tome Reader** featuring a 48×48 framed entry icon portrait, title/era/location badges, `Pin to Map` and `Delete` buttons, smooth `ScrollFrame` story text, clickable **Connected Lore & Backlink Cards**, and the compact Field Notes box.
- [x] **Step 3.4 (`UI/DossierView.lua`):** Build the visual **Evidence Board** view for `Dossier` entries, displaying the topic overview and a grid of discovered Clue Cards (Books, Quests, NPCs, and Relics automatically matched to that topic) that jump straight to the clue when clicked.