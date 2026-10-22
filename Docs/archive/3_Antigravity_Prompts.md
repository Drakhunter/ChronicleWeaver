# ChronicleWeaver — Antigravity Prompts (Step-by-Step)
**How to use:** Copy and paste **Prompt 0** at the start of a new Antigravity session to set the rules, then paste **one Step Prompt at a time** matching `2_Component_Todo_Roadmap.md`.

---

## Prompt 0: System Context & Engine Rules (Run First in New Sessions)
> You are working on **ChronicleWeaver**, a pure-Lua World of Warcraft addon for **WoW: Forever (`Interface: 16001`, client `1.60.1`)**.
> 
> **Strict Architecture & Engine Rules:**
> 1. The project uses exactly 5 files sharing the `local addonName, ns = ...` namespace: `ChronicleWeaver.toc`, `Core.lua`, `LoreDB.lua`, `Scanner.lua`, and `UI.lua`.
> 2. **Zero external libraries** (no Ace3, LibStub, or XML files). Use pure Lua frames with `BackdropTemplate`.
> 3. **Secret Value Guards (`16001` engine):** Never compare, concatenate, or index strings/booleans from WoW APIs (`UnitName`, `GetRealZoneText`, `tooltip:GetUnit`, `ItemTextGetText`) without guarding via `ns.IsSecret(val)` or `ns.SafeString(val, fallback)`.
> 4. **Combat Lockdown:** Never move or resize frames without checking `not InCombatLockdown()`.
> 5. **SavedVariables:** Never access `ChronicleWeaverDB` at file scope; only access `ns.db` after `ADDON_LOADED`.
> 6. Keep changes strictly scoped to the requested step. Do not rewrite unrelated modules.

---

## Prompt 2.1: Add Scrollable Story Reader & Mouse-Wheel Entry List (`UI.lua`)
> **Task (Step 2.1 — `UI.lua`):** Upgrade `UI.lua` so both the left-side entry list and the right-side story reader support smooth scrolling without overflowing their panels.
> 
> **Requirements:**
> 1. **Left Entry List (`listPanel`):**
>    - Keep the 11 reusable row buttons (`listButtons[1..11]`), but add a `listScrollOffset = 0` state variable.
>    - Enable mouse wheel on `listPanel` (`listPanel:EnableMouseWheel(true)`) with an `OnMouseWheel` script that increments/decrements `listScrollOffset` clamped between `0` and `math.max(0, #filtered - 11)`, then calls `ns.RefreshUI()`.
>    - Reset `listScrollOffset = 0` whenever the category tab or `searchQuery` changes.
>    - Display a small scroll indicator label (e.g., `"Showing 1-11 of 24"`) at the bottom of `listPanel` when `#filtered > 11`.
> 2. **Right Story Reader (`readerPanel`):**
>    - Create a `ScrollFrame` using `UIPanelScrollFrameTemplate` anchored below `entrySummary` and above `notesLabel` (leaving room for Related Lore chips above `notesLabel`).
>    - Create a scroll child frame inside the `ScrollFrame` and parent `entryStory` (and `revealBtn`) to that scroll child so multi-page harvested books scroll cleanly without overlapping the Personal Field Notes box.
>    - Reset vertical scroll to `0` (`SetVerticalScroll(0)`) whenever `selectedKey` changes.

---

## Prompt 2.2: Add Clickable "Related Lore" Jump-Chips (`UI.lua`)
> **Task (Step 2.2 — `UI.lua`):** Render clickable "Related Lore" navigation buttons inside `readerPanel` so players can jump directly between connected Books, NPCs, and Dungeons.
> 
> **Requirements:**
> 1. Above `notesLabel` inside `readerPanel`, create a `"Connected Lore:"` header label and a row of up to 4 reusable button chips (`relatedButtons[1..4]`, using `UIPanelButtonTemplate`, height `20`).
> 2. Inside `ns.RefreshUI()`, inspect `entry.related` (an array of `entryKey` strings).
> 3. If `entry.related` has valid keys in `ns.LoreByKey`, show up to 4 buttons labeled with each linked entry's `title` (truncated cleanly if needed) and color-coded by whether that linked entry is discovered (`|cff4cd964` vs `|cffaaaaaa`).
> 4. Clicking a chip must set `selectedKey = linkedKey`, reset the story scroll position, and call `ns.RefreshUI()`.
> 5. If an entry has no `related` keys, hide the `"Connected Lore:"` label and all 4 chip buttons.

---

## Prompt 2.3: Wire Up Automatic Bag & Item Tooltip Relic Scanner (`Scanner.lua`)
> **Task (Step 2.3 — `Scanner.lua`):** Finish the Relic/Item discovery pipeline so hovering over or looting a registered item automatically unlocks its lore entry and enhances its tooltip.
> 
> **Requirements:**
> 1. In `Scanner.lua`, hook `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ...)` (guarded with existence checks for `TooltipDataProcessor` and `Enum.TooltipDataType.Item`).
> 2. Inside the callback, safely extract the hovered item's `itemID` (e.g., via `tooltip:GetItem()` and `C_Item.GetItemInfoInstant` or `data.id`, guarded with `ns.IsSecret`).
> 3. If `ns.LoreByItem[itemID]` exists:
>    - Call `ns.InspectItemLore(itemID)` so hovering over the item in bags/loot unlocks the entry.
>    - Append a blank line, `|cffd4a85a[ChronicleWeaver Lore]|r`, and the entry's `summary` to the item tooltip.
> 4. Also register `BAG_UPDATE_DELAYED` to scan the player's bags (`C_Container.GetContainerNumSlots` and `C_Container.GetContainerItemID` for bags `0` to `4`) and call `ns.InspectItemLore(itemID)` on any matching Relic in `ns.LoreByItem`.

---

## Prompt 2.4: Add "Delete Saved Book" Button with Confirmation (`Core.lua` & `UI.lua`)
> **Task (Step 2.4 — `Core.lua` & `UI.lua`):** Allow players to delete unwanted harvested in-game books/letters from their Codex.
> 
> **Requirements:**
> 1. In `Core.lua`, add `ns.DeleteSavedBook(bookKey)`:
>    - Verify `ns.db.books[bookKey]` exists.
>    - Remove `ns.db.books[bookKey]`, `ns.db.discovered[bookKey]`, and `ns.db.notes[bookKey]`.
>    - Remove the entry from `ns.LoreByKey[bookKey]` and `ns.LoreEntries`.
>    - Print confirmation via `ns.Print(...)` and call `ns.RefreshUI()`.
> 2. In `UI.lua`, register a `StaticPopupDialogs["CHRONICLEWEAVER_DELETE_BOOK"]` confirmation dialog that calls `ns.DeleteSavedBook(data)`.
> 3. Add a small `"Delete"` button (`UIPanelButtonTemplate`) next to `pinBtn` in `readerPanel` that is ONLY shown when `entry.category == "Book"`. Clicking it opens the confirmation popup for `selectedKey`.

---

## Prompt 3.1: Build the "Souls-Like" Clue Synthesis & Deduction Engine (`LoreDB.lua`, `Scanner.lua`, `UI.lua`)
> **Task (Step 3.1 — `LoreDB.lua`, `Scanner.lua`, `UI.lua`):** Implement the Clue Synthesis system where discovering 2 or more specific entries automatically synthesizes and unlocks a hidden `"Deduction"` entry.
> 
> **Requirements:**
> 1. **In `LoreDB.lua`:**
>    - Add at least two example `category = "Deduction"`, `triggerType = "SYNTHESIS"` entries (e.g., `"synth:DarkIronConspiracy"` requiring `requiredClues = { "zone:Hall of Thanes", "npc:Faldrim Anvilmar", "npc:Durgen Dirgehammer" }`).
>    - Include a `ns.LoreSyntheses` list populated during `ns.BuildLoreIndex()`.
> 2. **In `Core.lua`:**
>    - Inside `ns.UnlockEntry(entryKey)`, after marking `entryKey` discovered, iterate through `ns.LoreSyntheses`.
>    - For any locked synthesis entry where ALL keys in `synth.requiredClues` are now present in `ns.db.discovered`, automatically unlock `synth.key` and trigger `ns.ShowDiscoveryToast(synth, true)` (passing an `isSynthesis = true` flag).
> 3. **In `UI.lua`:**
>    - Add `"Deduction"` to the `categories` filter bar (adjusting button widths so all 7 tabs fit cleanly).
>    - Update `ns.ShowDiscoveryToast(entry, isSynthesis)` so synthesis unlocks display a distinct purple border and header (`|cffc586c0LORE DEDUCTION SYNTHESIZED|r`).
>    - When viewing a locked `"Deduction"` entry in `readerPanel`, show a checklist of which prerequisite clues have been found vs. how many remain unknown (e.g., `"Clues Gathered: 2 / 3"`).