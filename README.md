<div align="center">
  <img src="Media/logo.png" alt="ChronicleWeaver Logo" width="180" />
  <h1>ChronicleWeaver</h1>
  <p><strong>Context-Aware Lore Codex, Investigative Dossiers & Field Journal for World of Warcraft: Forever</strong></p>

  <p>
    <img src="https://img.shields.io/badge/WoW%3A%20Forever-1.60.1%20(16001)-d4a85a?style=flat-square" alt="Client Version" />
    <img src="https://img.shields.io/badge/Version-1.2.0-ffd100?style=flat-square" alt="Addon Version" />
    <img src="https://img.shields.io/badge/License-MIT-4cd964?style=flat-square" alt="License" />
  </p>
</div>

---

**ChronicleWeaver** transforms your journey across Azeroth in **World of Warcraft: Forever** (`Interface: 16001`) into an interactive, spoiler-safe archivist's investigation.

Unlike static lore databases, **ChronicleWeaver** observes what you actually discover in-game—zones and dungeons you step into, notable figures you target, quests you complete, multi-page books and plaques you read, NPC dialogue you archive, and item flavor text you inspect—and weaves them together into a living **Lore Web** and **18 Grand Archivist Case Files (Dossiers)**.

---

## ✨ Key Features

### 🕵️ Grand Archivist Investigative Dossiers (`ARCH-01` – `ARCH-18`)
- **Cross-Zone Case Files**: 18 handcrafted investigative dossiers connecting *WoW: Forever* custom zones/dungeons (*Zephras Isle*, *The Hall of Thanes*, *Ruins of Lordaeron*, *Excavation Site: Wetlands*, *City of Dalaran*, *The Drowned City*, *Riverglades & Krol'dok Stronghold*, *Alcaz Prison*, *Shen'Dralas*, *Blackmaw Hold*, *Shaper's Terrace*, *Mount Hyjal*) with classic Warcraft history.
- **Live Investigation Progress Bar**: Tracks `Uncovered Evidence: X / Y Clues (Z%)` across linked Zones, Dungeons, NPCs, Quests, Books, and Relics.
- **The Archivist's Synthesis & Field Directives**: Each Dossier contains a hidden **Archivist's Synthesis** deduction that remains sealed under Spoiler-Safe protection until you uncover field clues in Azeroth, plus actionable **Field Directives** pointing you toward the zones and dungeons that hold the next piece of the mystery.

### 📖 Automatic Multi-Page Book, Quest & Relic Harvesting
- **Multi-Page Book & Plaque Harvester**: Automatically archives every page of in-game books, monuments, and plaques you read, complete with origin zone, coordinates, and a live `[OK] ChronicleWeaver: Page Archived` HUD badge on `ItemTextFrame`.
- **Pure-Story Quest & Gossip Archiver**: Records narrative quest descriptions and completion resolutions (automatically stripping out kill counters like `0/10 Slain`), plus a 1-click `[+] Archive Lore` button on `GossipFrame` to preserve NPC story dialogue.
- **Dynamic Relic Flavor Harvester**: Automatically detects and archives items with quoted lore flavor text when inspected in your bags or tooltips.

### 🕸️ Bi-Directional Lore Weaving & Strict Category Navigation
- **Automatic Keyword & Entity Weaving**: Dynamically highlights known entities, zones, dungeons, and dossier keywords inside every chronicle you read, generating clickable **Connected Lore & Mentioned In** backlink pills.
- **Strict Per-Category Top Tabs**: Dedicated tabs for `Zone`, `Dungeon`, `NPC`, `Relic`, `Book`, `Quest`, and `Dossier`.
  - `Dungeon`, `NPC`, `Relic`, `Book`, and `Quest` tabs organize entries into collapsible **Zone folders** (with `* Favorites` pinned at the top), or toggle to a flat list.
  - `Zone` and `Dossier` tabs present clean, scannable direct lists.
- **Dual-Theme Engine**: Switch seamlessly between **Royal Archivist Parchment** and **Midnight Obsidian** (`Theme: Parchment / Dark`).
- **Strict Spoiler-Safe Mode**: Undiscovered entries stay hidden from your index and redacted on Dossier Evidence Boards until you encounter them in Azeroth (with an optional manual reveal button).
- **World Map Waypoints & Personal Field Notes**: Pin any location-tagged entry directly to your World Map with `UiMapPoint` super-tracking, and jot down auto-saving personal field notes on every entry.

---

## ⌨️ Slash Commands & Controls

| Command / Input | Action |
| :--- | :--- |
| `/cw` or `/lorecodex` | Open / Close the ChronicleWeaver Tome |
| `/cw theme` | Toggle between **Parchment** and **Dark** themes |
| `/cw spoilers` | Toggle **Spoiler-Safe Mode** (`Hidden` / `Shown`) |
| `/cw toast` | Toggle animated **Discovery Toast** fanfare banners |
| `/cw scan` or `/cw quests` | Backfill narrative lore from your active Quest Log |
| `/cw help` | Print command reference in chat |
| **Minimap Addon Compartment** | **Left-Click**: Toggle Tome &nbsp;\|&nbsp; **Right-Click**: Toggle Spoiler-Safe Mode |
| **Sidebar Entry Row** | **Left-Click**: Read Chronicle &nbsp;\|&nbsp; **Right-Click**: Toggle `* Favorite` |

---

## 🗂️ Project Architecture

```text
ChronicleWeaver/
├── ChronicleWeaver.toc          # Interface 16001 manifest & load order
├── Core/
│   ├── Constants.lua            # Dual-theme palettes, category icons/tags & constants
│   ├── Utils.lua                # Secret-value guards (issecretvalue), map pins, unlock state
│   └── Init.lua                 # Event/message bus, SavedVariables schema & slash commands
├── Data/
│   ├── Lore_Classic.lua         # Curated Classic Azeroth zones, figures & relics
│   ├── Lore_Forever.lua         # Curated WoW: Forever zones, dungeons & bosses
│   ├── Lore_Topics.lua          # 18 Grand Archivist Investigative Dossiers (ARCH-01..18)
│   └── IndexBuilder.lua         # Compiles static lore & hydrates SavedVariables into runtime maps
├── Engine/
│   ├── WeaveEngine.lua          # Bi-directional backlinks, entity weaving & dossier clustering
│   ├── Scanner_World.lua        # Zone/subzone, target NPC, bag relic & tooltip hooks
│   ├── Scanner_Books.lua        # Multi-page book & plaque harvester + ItemTextFrame HUD badge
│   └── Scanner_Quests.lua       # Pure-story quest harvester + GossipFrame archive button
├── UI/
│   ├── ThemeEngine.lua          # Live Parchment / Midnight Obsidian backdrop & typography engine
│   ├── ToastBanner.lua          # Animated discovery fanfare toast banner
│   ├── MainFrame.lua            # Resizable 980x660 shell, 7 category tabs & header utilities
│   ├── SidebarList.lua          # Smart per-tab grouping, collapsible zone folders & search
│   ├── ReaderView.lua           # Parchment vignette, medallion portrait, backlink pills & notes
│   └── DossierView.lua          # Case header, progress bar, Synthesis card & clue grid
└── Media/
    ├── logo.tga / logo.png      # Custom ChronicleWeaver emblem
    ├── bg_parchment_vignette.tga
    ├── divider_filigree.tga
    └── frame_portrait_ring.tga
```

---

## 📦 Installation & Release Pipeline

### Manual Installation
1. Download the latest release `.zip` from **GitHub Releases** or **CurseForge**.
2. Extract into `World of Warcraft\_retail_\Interface\AddOns\ChronicleWeaver` (ensuring `ChronicleWeaver.toc` is directly inside `Interface\AddOns\ChronicleWeaver\`).

### Automated CI/CD (GitHub Actions + CurseForge / Wago)
This repository includes automated workflows in [`.github/workflows/`](.github/workflows/):
- **[`lint.yml`](.github/workflows/lint.yml)**: Runs `luacheck` and verifies every file path in `ChronicleWeaver.toc` on every push and pull request.
- **[`release.yml`](.github/workflows/release.yml)**: Uses `BigWigsMods/packager@v2` and [`.pkgmeta`](.pkgmeta) whenever a `v*` tag is pushed (e.g. `git tag v1.2.0 && git push origin v1.2.0`) to package a clean release `.zip`, publish a GitHub Release with [`CHANGELOG.md`](CHANGELOG.md), and upload to CurseForge / Wago / WoWInterface when repository secrets (`CF_API_KEY`, `WAGO_API_TOKEN`, `WOWI_API_TOKEN`) are configured.
