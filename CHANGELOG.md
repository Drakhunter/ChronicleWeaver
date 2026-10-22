# Changelog

## [1.2.3] - 2026-10-22

### Added
- **Over 75 Curated NPC Lore Chronicles (`Data/Lore_Classic.lua` & `Data/Lore_Forever.lua`)**: Added comprehensive biographical and investigative lore entries for Faction Leaders, Capital Sovereigns, Famous Quest Givers, Raid/World Bosses, and Dungeon Bosses across both Classic Azeroth and *WoW: Forever* custom zones/dungeons, complete with multi-name `aliases` support for targeting and tooltips.
- **18 Grand Archivist Investigative Dossiers (`ARCH-01` - `ARCH-18`)**: Deep lore investigations spanning Classic and *WoW: Forever* zones, dungeons, and notable NPCs with live investigation progress bars and progressive Archivist's Synthesis deduction cards.
- **Account-Wide vs. Per-Character Scope Toggle (`Scope: Account / Char`)**: Added header toggle button and `/cw scope` command to switch between Account-Wide and Current Character entries.
- **Custom Addon Emblem (`Media/logo.tga`)**: Integrated into the Addon List, Minimap Addon Compartment, and Main Window header.

### Changed & Fixed
- **Strict Category Tabs**: Top tabs (`Zone`, `Dungeon`, `NPC`, `Relic`, `Book`, `Quest`, `Dossier`) strictly isolate one category at a time with smart Zone-folder grouping and automatic cross-tab link navigation.
- **Quest Log Scanner Fix**: Fixed `C_QuestLog.SetSelectedQuest` selection during Quest Log scanning and added automatic deduplication for previously saved quests with identical descriptions.
