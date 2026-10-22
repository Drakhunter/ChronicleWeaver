# ChronicleWeaver — Component Todo-List & Roadmap
**Architecture:** `ChronicleWeaver.toc` | `Core.lua` | `LoreDB.lua` | `Scanner.lua` | `UI.lua`  
**Rule:** Complete and test ONE checkbox in-game before starting the next!

---

## Phase 1: Core Engine & MVP Foundation (COMPLETED ✅)
- [x] **Step 1.1 (`ChronicleWeaver.toc`):** Configure `Interface: 16001`, `SavedVariables: ChronicleWeaverDB`, and native Minimap Addon Compartment callbacks.
- [x] **Step 1.2 (`Core.lua`):** Build event dispatcher, `ADDON_LOADED` database initializer, `issecretvalue()` security guards, `/cw` slash commands, and `ns.PinEntryToMap()` waypoint helper.
- [x] **Step 1.3 (`LoreDB.lua`):** Set up static lore schema and fast lookup indexes (`LoreByKey`, `LoreByZone`, `LoreByNPC`, `LoreByItem`).
- [x] **Step 1.4 (`Scanner.lua`):** Implement Zone/Subzone scanner, Target NPC scanner, NPC Tooltip injection, and Multi-Page Book/Plaque Harvester (`ITEM_TEXT_READY`) with keyword highlighting.
- [x] **Step 1.5 (`UI.lua`):** Build Discovery Toast banner, draggable Main Codex window, Category tabs, Search box, Spoiler toggle, Pin to Map button, and Auto-Saving Personal Field Notes.

---

## Phase 2: UX Polish & Navigation (NEXT UP 🚧)
*Goal: Make the UI scale effortlessly to 100+ entries and multi-page books, and finish wiring item & cross-link interactions.*

- [ ] **Step 2.1 (`UI.lua` — Scrollable Story & Entry List):**
  - Wrap the right-side `entryStory` FontString inside a `UIPanelScrollFrameTemplate` so long multi-page books scroll smoothly without overflowing into the Field Notes box.
  - Add mouse-wheel scrolling (`OnMouseWheel`) and a scroll offset to the left-side `listPanel` so the user can browse more than 11 entries per category.
- [ ] **Step 2.2 (`UI.lua` — Clickable "Related Lore" Jump-Chips):**
  - Create a row of up to 4 small clickable pill buttons at the bottom of the story reader panel that render the titles of any keys in `entry.related`.
  - Clicking a chip sets `selectedKey` to that linked entry and refreshes the UI.
- [ ] **Step 2.3 (`Scanner.lua` — Automatic Bag & Item Tooltip Relic Scanner):**
  - Hook `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item)` (with safe fallback) to detect `itemID` when hovering over items in bags or loot windows.
  - Automatically call `ns.InspectItemLore(itemID)` and append a `[ChronicleWeaver Lore]` line to matching item tooltips.
- [ ] **Step 2.4 (`UI.lua` & `Core.lua` — Book Management / Delete Button):**
  - Add a small "Delete Book" button (visible only when viewing a harvested `category == "Book"` entry) with a `StaticPopupDialogs` confirmation prompt so players can remove unwanted or junk letters from `ChronicleWeaverDB.books`.

---

## Phase 3: Standout "Souls-Like" Features (BACKLOG 🌟)
*Goal: Deliver the killer differentiation features once Phase 2 feels rock-solid.*

- [ ] **Step 3.1 (`LoreDB.lua`, `Scanner.lua` & `UI.lua` — Clue Synthesis / Deduction Engine):**
  - Add `"Deduction"` to the category tabs and support `triggerType = "SYNTHESIS"` entries in `LoreDB.lua` with a `requiredClues = { "key1", "key2" }` table.
  - Whenever `ns.UnlockEntry()` unlocks a clue, check if any locked `SYNTHESIS` entry now has all its `requiredClues` discovered; if so, auto-unlock the Deduction and fire a purple `"LORE DEDUCTION SYNTHESIZED"` toast!
- [ ] **Step 3.2 (`Scanner.lua` & `Core.lua` — Optional NPC Gossip & Quest Lore Archiver):**
  - Add a toggleable setting (`ns.db.captureGossip`) that listens to `GOSSIP_SHOW` and `QUEST_DETAIL` to let players save memorable NPC story dialogues into their Codex with 1 click on the Gossip/Quest frame.