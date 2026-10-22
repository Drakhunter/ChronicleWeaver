# ChronicleWeaver — AAAA Product Specification & Customer Wishlist

## 1. Customer Vision ("Why This Addon Beats Everything on CurseForge")
As a WoW: Forever lore enthusiast, I don't want a static Wikipedia dump written by AI, and I don't want a barebones text-saver that dumps books into an ugly, unlinked list. 
I want an **Interactive Archaeologist’s Tome & Evidence Board** that:
1. **Looks like a real Blizzard Journal:** Warm parchment pages, framed 48×48 portraits, crisp native icons, and a 1-click toggle between *Archivist Parchment* and *Midnight Dark Mode*.
2. **Harvests real in-game lore automatically:** Saves every multi-page book, scroll, monument, flavor-text relic, and pure quest narrative I encounter—with exact map coordinates and a 1-click World Map waypoint pin.
3. **Connects the dots automatically ("The Lore-Weaver"):** Highlights known bosses, factions, and zones in gold inside every book or quest I read, builds automatic bi-directional backlinks (*"Mentioned In..."*), and clusters my discoveries into visual **Lore Dossiers (Evidence Boards)** without requiring thousands of hand-written essays.

---

## 2. Core Feature Pillars

### Pillar I: AAA Visuals & Ergonomics (`UI/`)
- **Spacious, Resizable Split-Tome (`980×660` default, resizable up to `1400×950`):**
  - **Left Pane (`SidebarList.lua`):** High-contrast index with 16×16 inline icons (no broken ASCII/Unicode brackets), strictly single-line truncated titles (`SetMaxLines(1)`), smooth mouse-wheel scrolling + draggable gold scrollbar thumb, Right-Click **Favorite (`★`)** pinning, and toggleable **Group by Zone** collapsible headers.
  - **Right Pane (`ReaderView.lua` & `DossierView.lua`):** Framed **48×48 Icon Medallion** header, Era/Provenance badges, **"Pin to Map"** & **"Delete"** action buttons, smooth scrollable story body, interactive **Connected Lore & Backlink Cards**, and a compact auto-saving **Personal Field Notes** drawer.
- **Dual-Theme Engine (`ThemeEngine.lua` + `Media/`):**
  - Instant toggle between **Royal Archivist Parchment** (using Blizzard `EncounterJournal` / `QuestBG` atlases or custom `Media/` textures) and **Midnight Obsidian** (warm ivory text on dark slate).

### Pillar II: The Omniscient In-Game Harvester (`Engine/Scanner_*.lua`)
- **Multi-Page Book, Scroll & Plaque Harvester (`Scanner_Books.lua`):**
  - Captures every page on `ITEM_TEXT_READY` indexed by `ItemTextGetPage()` so flipping pages never overwrites Page 1.
  - Stamps exact Zone, Subzone, `uiMapID`, and `(x, y)` coordinates.
  - **Live HUD Badge on `ItemTextFrame`:** Displays `"✓ Page 1/2 Archived in ChronicleWeaver"` directly on Blizzard's book frame so players know when all pages are captured.
- **Pure-Story Quest & Gossip Harvester (`Scanner_Quests.lua`):**
  - Captures only the narrative meat: **Quest Description (`GetQuestText()` / `GetQuestLogQuestText()`)** and **Turn-In Resolution (`GetRewardText()`)**, plus Quest Giver and location. Completely ignores kill counters (`10/12 Raptor Head`) and progress text.
  - **Quest Log Backfill:** On login, scans active quests using `GetQuestLogQuestText()` to populate full lore descriptions for quests already in the player's log.
  - **"📜 Archive Lore" Gossip Button:** Adds a small button on `GossipFrame` so players can selectively save rich NPC story dialogues with 1 click without filling their library with innkeeper trash.
- **World, Boss & Flavor-Text Relic Scanner (`Scanner_World.lua`):**
  - Unlocks Zone/Subzone and Target NPC entries automatically.
  - Scans bags and item tooltips (`Enum.TooltipDataType.Item`) to unlock curated Relics AND dynamically harvest any item with quoted yellow lore flavor text (`"..."`), saving its real item icon and link.

### Pillar III: The "Lore-Weaver" & Dynamic Dossiers (`Engine/WeaveEngine.lua` & `Data/Lore_Topics.lua`)
- **Automatic Keyword Highlighting:** Scans every harvested Book, Quest, Relic, and Gossip text for known Entities and Topic keywords, highlighting matches in gold (`|cffffd100[Keyword]|r`).
- **Bi-Directional Backlinks ("Mentioned In..."):** If Book A or Quest B mentions *Faldrim Anvilmar*, viewing *Faldrim Anvilmar*'s NPC page automatically lists Book A and Quest B under **"Mentioned In"**—and vice versa!
- **Dynamic Topic Dossiers (`Dossier` Tab):**
  - Instead of requiring hundreds of hand-written deduction essays, `Lore_Topics.lua` defines lightweight Lore Themes (e.g., *The Defias Brotherhood*, *Secrets of Old Ironforge*, *The Scourge of Silverpine*, *The Cult of the Burning Blade*) using a title, icon, short overview, and a keyword watch-list.
  - As the player discovers matching Books, Quests, Relics, and Bosses in-game, the Dossier automatically populates a visual **Evidence Board** grouping every clue they've uncovered on that topic!
