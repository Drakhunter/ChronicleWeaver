# Changelog

All notable changes to **ChronicleWeaver** will be documented in this file.

## [1.2.0] - 2026-10-22

### Added
- **Grand Archivist Investigative Dossiers (ARCH-01 through ARCH-18)**:
  - 18 deep, cross-zone lore investigations connecting Classic and *World of Warcraft: Forever* storylines (*Zephras Isle & Skywall*, *The Hall of Thanes & War of the Three Hammers*, *Alcaz Prison & The Defias Conspiracy*, *Necromancer Rath'mael & The Ruins of Lordaeron*, *City of Dalaran Quarantine*, *Excavation Site: Wetlands, Uldaman & Shaper's Terrace*, *The Drowned City & Atal'Hakkar*, *Riverglades & Krol'dok Stronghold*, *Shen'Dralas & Dire Maul*, *Blackmaw Hold & Mount Hyjal*, and more).
  - **Live Investigation Progress Bar**: Tracks `Uncovered Evidence: X / Y Clues (Z%)` across linked Zones, Dungeons, NPCs, Quests, Books, and Relics.
  - **The Archivist's Synthesis & Field Directives**: Progressive deduction card that stays sealed in Spoiler-Safe mode until you uncover field evidence in Azeroth, then reveals how the clues secretly connect along with actionable exploration leads.
- **Custom ChronicleWeaver Emblem (`Media/logo.tga`)**:
  - Added high-craft custom emblem to the Addon List, Minimap Addon Compartment button, and Main Window header.
- **12 Notable Boss & Lore Figure Entries**:
  - Added dedicated NPC chronicles for `Necromancer Rath'mael`, `Archmage Ansirem Runeweaver`, `High Warlord Krol'dok`, `King Varian Wrynn`, `Naralex`, `Ancient Stone Keeper Archaedas`, `Princess Theradras`, `Prince Tortheldrin`, `Emperor Dagran Thaurissan`, `High Inquisitor Sally Whitemane`, `Baron Titus Rivendare`, and `Darkmaster Gandling`.

### Changed
- **Strict Per-Category Navigation Tabs**:
  - Removed the mixed `"ALL"` tab so the 7 top navigation tabs (`Zone`, `Dungeon`, `NPC`, `Relic`, `Book`, `Quest`, `Dossier`) strictly display one category at a time.
  - **Smart Per-Tab Sidebar Grouping**: `Dungeon`, `NPC`, `Relic`, `Book`, and `Quest` tabs group entries into collapsible Zone folders (with `* Favorites` pinned at top), while `Zone` and `Dossier` tabs render as clean direct lists without redundant 1-item folders.
  - **Cross-Tab Link Navigation**: Clicking any Connected Lore pill, Dossier Clue card, or Discovery Toast automatically switches the active top tab to the target entry's category and scrolls it into view.
