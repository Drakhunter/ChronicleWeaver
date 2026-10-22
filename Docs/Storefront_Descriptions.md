# Storefront & Repository Metadata Guide (`ChronicleWeaver`)

Use the pre-formatted metadata, descriptions, and tags below when setting up **GitHub**, **CurseForge**, **Wago Addons**, and **WoWInterface**.

---

## 1. GitHub Repository Settings (About Box)

- **Short Description (max 160 chars)**:
  > Context-aware lore codex, Grand Archivist investigative dossiers, multi-page book harvester, and personal field journal for World of Warcraft: Forever.
- **Topics / Tags**:
  `world-of-warcraft` `wow-addon` `wow-classic-plus` `wow-forever` `lore` `codex` `roleplay` `lua` `quest-log`

---

## 2. CurseForge / Wago Short Summary (Tagline)

> **Short Summary (1-line)**:
> Investigative lore codex, 18 Grand Archivist Case File Dossiers, automatic multi-page book/quest/relic harvester, and personal field journal for WoW: Forever.

- **Primary Category**: `Roleplay`
- **Secondary Categories**: `Quests & Leveling`, `Map & Minimap`, `Achievements`
- **Addon Project ID Setup**:
  Once you create your project on CurseForge and Wago, paste the numeric IDs into [`ChronicleWeaver.toc`](../ChronicleWeaver.toc):
  ```ini
  ## X-Website: https://github.com/Drakhunter/ChronicleWeaver
  ## X-Curse-Project-ID: 1759004
  ## X-Wago-ID: YOUR_WAGO_ID
  ```
- **GitHub Actions Secrets** (`Settings -> Secrets and variables -> Actions`):
  - `CF_API_KEY`: Your CurseForge API Token
  - `WAGO_API_TOKEN`: Your Wago Addons API Token
  - `WOWI_API_TOKEN`: Your WoWInterface API Token (optional)

---

## 3. Full CurseForge / Wago Storefront Description (Markdown)

Copy and paste the block below directly into the **CurseForge / Wago Project Description** editor:

```markdown
# ChronicleWeaver — The Forever Lore Codex

**ChronicleWeaver** turns your adventures across **World of Warcraft: Forever** into a living, spoiler-safe archivist's investigation.

Instead of a static encyclopedia, **ChronicleWeaver** tracks what you actually experience in Azeroth—the zones and dungeons you enter, notable characters and bosses you encounter, multi-page books and plaques you read, story quests you complete, NPC dialogues you archive, and ancient relics you inspect—and weaves them together into an interconnected **Lore Web**.

---

## What Makes ChronicleWeaver Unique?

### 1. Grand Archivist Investigative Dossiers (ARCH-01 to ARCH-18)
Piece together **18 deep, cross-zone conspiracies and historical mysteries** spanning Classic Azeroth and *WoW: Forever*:
* **The Skyborne Awakening & The Rifts of Skywall** (*Zephras Isle*)
* **The War of the Three Hammers & The Vaults of Old Ironforge** (*The Hall of Thanes*, *Ironforge*, *Blackrock Depths*)
* **The Stonemasons' Ledger, VanCleef & The Missing King** (*Westfall*, *The Deadmines*, *The Stockade*, *Alcaz Prison*)
* **Ashes of the Terenas Dynasty & The Wrath of Rath'mael** (*Ruins of Lordaeron*, *Scholomance*, *Stratholme*)
* **The Makers' Blueprint: From Wetlands to Shaper's Terrace** (*Excavation Site: Wetlands*, *Uldaman*, *Shaper's Terrace*)
* **The Sunken Ziggurats: From the Drowned City to Atal'Hakkar** (*The Drowned City*, *Stranglethorn Vale*, *Temple of Atal'Hakkar*, *Zul'Farrak*)
* **The Krol'dok Confederacy & The Riverglades Frontier** (*Riverglades*, *Krol'dok Stronghold*)
* **Ghosts of Eldre'Thalas: Shen'Dralas, Dire Maul & The Highborne** (*Shen'Dralas*, *Dire Maul*, *Feralas*)
* **The Tainted Bough: Blackmaw Hold, Felwood & Mount Hyjal** (*Blackmaw Hold*, *Azshara*, *Felwood*, *Mount Hyjal*)
* *...and 9 more overarching investigations!*

Each Dossier features:
* **Live Investigation Progress Bar**: Tracks `X / Y Clues Found (Z%)` across linked Zones, Dungeons, NPCs, Quests, Books, and Relics.
* **The Archivist's Synthesis (Progressive Deduction)**: A hidden deduction card that remains sealed in Spoiler-Safe mode until you uncover field clues in-game, then reveals how the disparate events secretly connect.
* **Field Directives**: Actionable lore leads telling you which zones and dungeons hold the missing pieces of the investigation.

### 2. Automatic In-Game Lore Harvesting
* **Multi-Page Book & Plaque Harvester**: Every page of every in-game book, tome, scroll, and plaque you read is permanently archived with its origin zone, coordinates, and a live `[OK] ChronicleWeaver: Page Archived` badge on the book frame.
* **Pure-Story Quest & Gossip Archiver**: Captures quest story descriptions and completion resolutions (automatically filtering out kill counters like `0/10 Slain`), plus a 1-click `[+] Archive Lore` button on NPC gossip windows.
* **Dynamic Relic Flavor Harvester**: Automatically archives items with quoted flavor text when inspected in your bags or tooltips.

### 3. Bi-Directional Lore Weaving & Dual-Theme UI
* **Connected Lore & Backlinks**: Names of known characters, places, and topics are dynamically highlighted in your reading view and linked via clickable bottom navigation pills.
* **Strict Category Tabs & Smart Zone Folders**: Dedicated top tabs for **Zone**, **Dungeon**, **NPC**, **Relic**, **Book**, **Quest**, and **Dossier**, with collapsible Zone folders, Faction filters, Favorites (`*`), and instant search.
* **Dual-Theme Engine**: Toggle anytime between **Royal Archivist Parchment** and **Midnight Obsidian** (`Theme: Parchment / Dark`).
* **Spoiler-Safe Protection**: Keep undiscovered lore shrouded in mystery until you encounter it in-game.
* **World Map Waypoints & Personal Field Notes**: Pin any coordinate-tagged chronicle to your World Map and write auto-saved personal notes on any entry.

---

## Slash Commands
* `/cw` or `/lorecodex` — Open / Close the Lore Codex
* `/cw theme` — Switch between **Parchment** and **Dark** themes
* `/cw spoilers` — Toggle **Spoiler-Safe Mode**
* `/cw toast` — Toggle **Discovery Toast** banners
* `/cw scan` — Harvest narrative lore from your active Quest Log
* `/cw help` — Display all commands
```
