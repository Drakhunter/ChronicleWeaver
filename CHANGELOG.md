# Changelog

## [1.3.0] - 2026-11-20

### Added
- ***WoW: Forever* Library Book Delivery Hints & Interactive 35-Book Ledger**: Automatic faction librarian turn-in guidance (**Garion Wendell** in Stormwind City `49.0, 86.3` for Alliance; **Owen Thadd** in Undercity `74.0, 32.5` for Horde) across item tooltips, chat harvest alerts, and the Codex Reader (`Pin Turn-In` button), plus a dedicated Library Ledger panel (`/cw ledger`, `/cw nearest`) with live progress tracking and `Pin Nearest Missing`.
- **General Options Drawer (`/cw options`, `/cw quests`)**: Dedicated settings view for toggling automatic Quest, Book, Relic, and World scanning, Gossip capture button visibility, Spoiler-Safe mode, Delivery Hints, Item Tooltips, Auto-Toasts, Soundscapes (`Chime / Page Turn / Fanfare / Muted`), and Toast Position locking.
- **Rich Codex UX & Navigation**: Clickable inline hyperlinked terms (`|Hcw:<key>|h`) inside chronicle prose and Dossier syntheses, Storyteller Wide Mode (`Wide`/`Split`), `<- Back` navigation history, per-entry scroll position memory, Chronological `Group: Zone / Era / Flat` sidebar organization, `Era:` filter (`All / Forever+ / Classic / Harvested`), and right-click Zone folder pinning.
- **World Map Cartography Bar, Proximity Radar, Peer Sync & Export**: Added an interactive `Pin Missing` bar on `WorldMapFrame`, proximity "Archivist's Whisper" radar toasts, `CW_LORE` party/raid/guild peer sharing (`Share`), and Markdown/Lua community export (`/cw export`).
- **Expanded Static Lore Database (280 Unique Keys) & Grand Archivist Dossiers (`ARCH-19` - `ARCH-25`)**: Added 7 Classic Raid dungeons (*Molten Core*, *Onyxia's Lair*, *Blackwing Lair*, *Zul'Gurub*, *Ruins of Ahn'Qiraj*, *Temple of Ahn'Qiraj*, *Naxxramas*), 27 Classic & *WoW: Forever* NPCs/Scholars/Archivists, 28 Curated Relics/Keys/Librams & *Friend of the Library* milestone collections, and 7 new Grand Archivist Dossiers (`ARCH-19` through `ARCH-25`).

## [1.2.6] - 2026-11-18

### Added
- **Over 75 Curated NPC Lore Chronicles (`Data/Lore_Classic.lua` & `Data/Lore_Forever.lua`)**: Added comprehensive biographical and investigative lore entries for Faction Leaders, Capital Sovereigns, Famous Quest Givers, Raid/World Bosses, and Dungeon Bosses across both Classic Azeroth and *WoW: Forever* custom zones/dungeons, complete with multi-name `aliases` support for targeting and tooltips.
- **18 Grand Archivist Investigative Dossiers (`ARCH-01` - `ARCH-18`)**: Deep lore investigations spanning Classic and *WoW: Forever* zones, dungeons, and notable NPCs with live investigation progress bars and progressive Archivist's Synthesis deduction cards.
- **Account-Wide vs. Per-Character Scope Toggle (`Scope: Account / Char`)**: Added header toggle button and `/cw scope` command to switch between Account-Wide and Current Character entries.
- **Custom Addon Emblem (`Media/logo.tga`)**: Integrated into the Addon List, Minimap Addon Compartment, and Main Window header.

### Changed & Fixed
- **Lore Web & Quest Scanner Performance**: Pre-compiled frontier patterns, cached normalized search strings, added debounced lore-web rebuild scheduling, and skipped redundant quest log re-indexing for already-recorded quests.
- **Strict Category Tabs**: Top tabs (`Zone`, `Dungeon`, `NPC`, `Relic`, `Book`, `Quest`, `Dossier`) strictly isolate one category at a time with smart Zone-folder grouping and automatic cross-tab link navigation.
- **Quest Log Scanner Fix**: Fixed `C_QuestLog.SetSelectedQuest` selection during Quest Log scanning and added automatic deduplication for previously saved quests with identical descriptions.
