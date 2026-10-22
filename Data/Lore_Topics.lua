-- =========================================================================
-- Data/Lore_Topics.lua
-- Grand Archivist Case Files & Investigative Lore Dossiers for WeaveEngine.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local addonName, ns = ...

ns.RawLoreTopics = {
    -- =====================================================================
    -- 1. THE SKYBORNE & ZEPHRAS ISLE
    -- =====================================================================
    {
        key = "dossier:SkyborneMysteries",
        category = "Dossier",
        caseId = "ARCH-01",
        classification = "Planar Convergence & Lineage",
        archivist = "Arcanist Taelis Windwatcher",
        title = "The Skyborne Awakening & The Rifts of Skywall",
        era = "Great Sea & Skywall",
        faction = "Neutral",
        icon = "Interface\\Icons\\Spell_Nature_Cyclone",
        zones = { "Zephras Isle", "Great Sea", "Azshara", "Tanaris" },
        keywords = { "Zephras", "Skyborne", "Windshaper", "Windshapers", "High Order", "Skywall", "Tempest" },
        summary = "An investigation into the storm-shrouded emergence of Zephras Isle and the ancient elven bloodline touched by the Elemental Plane of Air.",
        story = "For ten millennia following the Great Sundering, mariners crossing the Great Sea spoke of a perpetual cyclone where compass needles spun wild and ships vanished into blinding white squalls. Only recently did the tempest part to reveal Zephras Isle—an archipelago anchored partially within the mortal world and partially within the outer boundary of Skywall, the Elemental Plane of Air.\n\nIts inhabitants, the Skyborne, are descendants of an ancient Highborne expedition whose vessels were pulled into an elemental slipstream when the first Well of Eternity collapsed. Sustained for ages by tempest shrines and pacts with the lords of the Four Winds, their centuries of isolation ended when seismic shockwaves fractured the planar wards protecting their sanctuary.",
        synthesis = "Cross-referencing ancient Highborne star-charts with elemental readings from Zephras Isle reveals that the Skyborne split is no mere political disagreement. The Alliance-aligned High Order seeks to stabilize the failing Skywall wards through disciplined arcane geometry, whereas the Horde-aligned Windshapers believe the planar barrier can never be resealed—and that mortals must instead channel the raw fury of the storm before Al'Akir's lieutenants reclaim the island.",
        leads = "Survey the tempest shrines across Zephras Isle (Levels 1-12) and trace Highborne coastal ruins along the Bay of Storms in Azshara.",
        related = { "zone:Zephras Isle" },
    },

    -- =====================================================================
    -- 2. WAR OF THE THREE HAMMERS & HALL OF THANES
    -- =====================================================================
    {
        key = "dossier:ThreeHammers",
        category = "Dossier",
        caseId = "ARCH-02",
        classification = "Royal Succession & Subterranean Sabotage",
        archivist = "Historian Karnik, Explorers' League",
        title = "The War of the Three Hammers & The Vaults of Old Ironforge",
        era = "Khaz Modan",
        faction = "Alliance",
        icon = "Interface\\Icons\\INV_Hammer_09",
        zones = { "Ironforge", "Old Ironforge", "Hall of Thanes", "Dun Morogh", "Loch Modan", "Searing Gorge", "Burning Steppes", "Badlands" },
        keywords = { "Ironforge", "Anvilmar", "Bronzebeard", "Dark Iron", "Thanes", "Dirgehammer", "Khaz Modan", "Modimus", "Thaurissan", "Wildhammer" },
        summary = "The centuries-old succession crisis that shattered the dwarven kingdom, now reignited beneath Ironforge's sealed royal crypts.",
        story = "Before the War of the Three Hammers, the Bronzebeard, Wildhammer, and Dark Iron clans dwelt beneath a single mountain roof under the rule of High King Modimus Anvilmar. When Modimus passed into stone, simmering factional bitterness erupted into brutal civil war inside the very streets of Ironforge. The Bronzebeards prevailed, driving the Wildhammers to the peaks of Grim Batol and the Dark Irons to the volcanic depths of Redridge.\n\nYet the past refused to stay buried. Deep beneath the Great Forge lies the Hall of Thanes—the sacred necropolis housing the sarcophagi of the pre-schism High Kings. Recently, Dark Iron boring machines breached the West Wing of the crypts under Overseer Durgen Dirgehammer, waking the petrifying spirit of Thane Faldrim Anvilmar.",
        synthesis = "Why would Emperor Dagran Thaurissan risk an elite strike team inside the heart of Ironforge's mountain just to loot ancient tombs? Field reports from the Hall of Thanes indicate Dirgehammer's sappers are not after gold: they are hunting the original Stone Charters of Modimus Anvilmar. With Princess Moira Bronzebeard now wed to Thaurissan in Blackrock Depths, possessing the Anvilmar royal seal would give the Dark Iron Emperor a legal claim to the High Throne of Ironforge itself.",
        leads = "Descend into The Hall of Thanes beneath Old Ironforge (Levels 13-18), confront Overseer Durgen Dirgehammer and Thane Faldrim Anvilmar, then trace the conspiracy south to Blackrock Depths.",
        related = { "zone:Hall of Thanes", "zone:Ironforge", "zone:Dun Morogh", "zone:Loch Modan", "zone:Searing Gorge", "zone:Blackrock Depths", "npc:Faldrim Anvilmar", "npc:Durgen Dirgehammer", "npc:Emperor Dagran Thaurissan" },
    },

    -- =====================================================================
    -- 3. THE DEFIAS BROTHERHOOD & ALCAZ PRISON
    -- =====================================================================
    {
        key = "dossier:DefiasConspiracy",
        category = "Dossier",
        caseId = "ARCH-03",
        classification = "Crown Treason & Clandestine Insurrection",
        archivist = "Master Mathias Shaw, SI:7",
        title = "The Stonemasons' Ledger, VanCleef & The Missing King",
        era = "Stormwind & Dustwallow",
        faction = "Alliance",
        icon = "Interface\\Icons\\INV_Helmet_47",
        zones = { "Elwynn Forest", "Westfall", "The Deadmines", "Stormwind City", "The Stockade", "Redridge Mountains", "Dustwallow Marsh", "Alcaz Prison" },
        keywords = { "VanCleef", "Defias", "Stonemason", "Westfall", "Deadmines", "Stockade", "Thredd", "Varian", "Wrynn", "Alcaz", "Prestor" },
        summary = "Tracing the invisible chain of gold and blackmail linking Westfall's red-masked rebels, the Stockade riots, and King Varian Wrynn's abduction at Alcaz Island.",
        story = "On the surface, the Defias Brotherhood is a tragic tale of working-class betrayal: after Master Edwin VanCleef and the Stonemasons Guild rebuilt Stormwind City in the wake of the First War, the House of Nobles refused to honor their debt. Cast out into the dust bowls of Westfall, the artisans donned red bandanas and converted the Moonbrook gold mines into a subterranean shipyard to construct an ironclad juggernaut.\n\nHowever, SI:7 intercepts reveal an operation far too sophisticated for destitute masons. Simultaneously, Bazil Thredd orchestrated a coordinated uprising inside Stormwind's Stockade, while across the Great Sea in Dustwallow Marsh, elite Defias cutthroats were discovered garrisoning the island fortress of Alcaz Prison alongside naga and black dragonkin.",
        synthesis = "Every link in the Defias chain leads back to Stormwind Keep. The same noble faction led by Lady Katrana Prestor that bankrupted the Stonemasons also blocked troop deployments to Westfall, Redridge, and Duskwood. Even more damning: shipping manifests recovered from the Deadmines match supply crates found inside Alcaz Prison—the exact island redoubt where High King Varian Wrynn was secretly held after his diplomatic vessel bound for Theramore was ambushed.",
        leads = "Infiltrate The Deadmines in Westfall (Levels 17-24), quell Bazil Thredd's riot in The Stockade (Levels 24-32), and storm Alcaz Prison in Dustwallow Marsh (Levels 48-53).",
        related = { "zone:Elwynn Forest", "zone:Westfall", "zone:Redridge Mountains", "zone:The Deadmines", "zone:The Stockade", "zone:Dustwallow Marsh", "zone:Alcaz Prison", "npc:Edwin VanCleef", "npc:King Varian Wrynn" },
    },

    -- =====================================================================
    -- 4. THE FALL OF LORDAERON & WRATH OF RATH'MAEL
    -- =====================================================================
    {
        key = "dossier:FallOfLordaeron",
        category = "Dossier",
        caseId = "ARCH-04",
        classification = "Necromantic Threat & Royal Ruin",
        archivist = "Royal Apothecary Society & Argent Dawn",
        title = "Ashes of the Terenas Dynasty & The Wrath of Rath'mael",
        era = "Northern Lordaeron",
        faction = "Horde",
        icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
        zones = { "Tirisfal Glades", "Ruins of Lordaeron", "Western Plaguelands", "Eastern Plaguelands", "Scholomance", "Stratholme", "Hillsbrad Foothills" },
        keywords = { "Lordaeron", "Rath'mael", "Undercity", "Sylvanas", "Forsaken", "Scholomance", "Gandling", "Stratholme", "Rivendare", "Scourge", "Plaguelands" },
        summary = "From the rose-strewn throne room where Arthas slew King Terenas to Necromancer Rath'mael's ritual above the Undercity.",
        story = "When the bell towers of Capital City rang out to welcome Prince Arthas Menethil home from Northrend, none suspected that the fallen paladin carried the runeblade Frostmourne. With a single stroke in the imperial throne room, seven centuries of Lordaeron's humanity ended in blood and plague. While Sylvanas Windrunner later wrenched freedom from the Lich King's grasp and carved the Undercity beneath the royal crypts, the shattered surface palaces remained haunted no-man's-land.\n\nNow, Cult of the Damned cells trained under Darkmaster Gandling in Scholomance and supplied by Baron Rivendare's legions in Stratholme have infiltrated the upper Ruins of Lordaeron. Led by Necromancer Rath'mael, they have begun binding the tormented ghosts of Terenas's slaughtered court into a necrotic siege engine.",
        synthesis = "Rath'mael's ritual in the Ruins of Lordaeron is no isolated incursion—it is a surgical strike directed from the Eastern Plaguelands. By turning the lingering royal spirits of Capital City into an anchor for Kel'Thuzad's blight magic, the Scourge aims to collapse the ceiling of the Undercity from directly above while the Forsaken war effort is tied down fighting Southshore in Hillsbrad.",
        leads = "Purge Necromancer Rath'mael from the Ruins of Lordaeron (Levels 15-20), dismantle Darkmaster Gandling's academy in Scholomance (Levels 58-60), and challenge Baron Rivendare in Stratholme (Levels 58-60).",
        related = { "zone:Tirisfal Glades", "zone:Ruins of Lordaeron", "zone:Hillsbrad Foothills", "zone:Western Plaguelands", "zone:Eastern Plaguelands", "zone:Scholomance", "zone:Stratholme", "npc:Rath'mael", "npc:Darkmaster Gandling", "npc:Baron Rivendare" },
    },

    -- =====================================================================
    -- 5. THE SCARLET CRUSADE & THE CRIMSON INQUISITION
    -- =====================================================================
    {
        key = "dossier:ScarletZealotry",
        category = "Dossier",
        caseId = "ARCH-05",
        classification = "Fanatical Order & Demonic Infiltration",
        archivist = "Leonid Barthalomew the Revered",
        title = "The Crimson Inquisitors & The Balnazzar Deception",
        era = "Tirisfal & Plaguelands",
        faction = "Contested",
        icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
        zones = { "Scarlet Monastery", "Tirisfal Glades", "Ruins of Lordaeron", "Western Plaguelands", "Eastern Plaguelands", "Stratholme" },
        keywords = { "Scarlet", "Monastery", "Whitemane", "Mograine", "Dathrohan", "Crusade", "Inquisitor", "Crimson" },
        summary = "How the noblest survivors of the Silver Hand descended into paranoid madness under a secret demonic puppeteer.",
        story = "In the dark days after Uther the Lightbringer fell and Lordaeron collapsed, the surviving paladins and priests banded together to form the Scarlet Crusade. Vowing to cleanse the undead blight at any cost, they fortified the Scarlet Monastery in Tirisfal Glades, Hearthglen in the Western Plaguelands, and the Crimson Bastion inside burning Stratholme.\n\nYet courage swiftly curdled into terror and fanaticism. Under High Inquisitor Sally Whitemane, Scarlet Commander Renault Mograine, and Grand Crusader Saidan Dathrohan, the Crusade began torturing and executing living refugees suspected of carrying even a trace of the plague—treating both Alliance and Horde outsiders as impure heretics.",
        synthesis = "Why can fanatics who murder the innocent still call upon the Holy Light, and why does the Crusade sabotage the Argent Dawn at every turn? Testimonies from Stratholme and the Scarlet Monastery point to a horrifying truth: Grand Crusader Dathrohan was slain during the early battles in Stratholme, and his corpse was possessed by the Nathrezim dreadlord Balnazzar. Every Scarlet atrocity has been engineered by a demon of the Burning Legion to ensure the living never unite against the undead.",
        leads = "Storm the four wings of the Scarlet Monastery in Tirisfal Glades (Levels 32-45) and confront the Crimson Bastion inside Stratholme (Levels 58-60).",
        related = { "zone:Scarlet Monastery", "zone:Tirisfal Glades", "zone:Ruins of Lordaeron", "zone:Western Plaguelands", "zone:Eastern Plaguelands", "zone:Stratholme", "npc:High Inquisitor Whitemane" },
    },

    -- =====================================================================
    -- 6. ARUGAL, SHADOWFANG & THE SCYTHE OF ELUNE
    -- =====================================================================
    {
        key = "dossier:SilverpineCurse",
        category = "Dossier",
        caseId = "ARCH-06",
        classification = "Forbidden Summoning & Lycanthropic Curse",
        archivist = "Deathstalker Commander Belmont &Watcher Ladimore",
        title = "Archmage Arugal, The Scythe of Elune & The Worgen Pack",
        era = "Silverpine & Duskwood",
        faction = "Contested",
        icon = "Interface\\Icons\\Spell_Shadow_GatherShadows",
        zones = { "Silverpine Forest", "Shadowfang Keep", "Duskwood", "Ashenvale", "Felwood" },
        keywords = { "Arugal", "Shadowfang", "Worgen", "Pyrewood", "Gilneas", "Silverlaine", "Duskwood", "Scythe", "Elune", "Ur" },
        summary = "Two separate catastrophes—a desperate wizard in Silverpine and a night elf priestess in Duskwood—that unleashed the same extraplanar wolf-beasts upon Azeroth.",
        story = "When the Scourge razed Dalaran, the royal patriot Archmage Arugal unlocked the sealed research of the deceased mage Ur, summoning ravenous wolf-men known as the Worgen to Tear apart the undead. The feral beasts soon turned upon the living soldiers of Gilneas, storming Baron Silverlaine's keep above Pyrewood Village. Driven mad by guilt, Arugal adopted the pack as his children within Shadowfang Keep, cursing the villagers below to transform by night.\n\nHundreds of miles south in the perpetual twilight of Duskwood, a second worgen outbreak simultaneously besieged the Night Watch of Darkshire—raising a chilling question among scholars: how did Arugal's monsters cross an entire continent?",
        synthesis = "They did not march from Silverpine—they were summoned twice from the same Emerald Dream prison. While Arugal used Ur's arcane rituals in Shadowfang Keep, the Kaldorei sentinel Velinde Starsong wielded a sacred relic called the Scythe of Elune to call Worgen against demons in Ashenvale and Felwood. Travelling south to seek Arugal's counsel, Velinde was ambushed in Roland's Doom in Duskwood, leaving the Scythe buried in the dark mines to continuously tear open portals for the pack.",
        leads = "Ascend Shadowfang Keep in Silverpine Forest (Levels 22-30) to face Archmage Arugal, and investigate the cursed mines of Duskwood (Levels 18-30).",
        related = { "zone:Silverpine Forest", "zone:Shadowfang Keep", "zone:Duskwood", "zone:Ashenvale", "zone:Felwood", "npc:Archmage Arugal" },
    },

    -- =====================================================================
    -- 7. DALARAN QUARANTINE & THE ALTERAC FRONT
    -- =====================================================================
    {
        key = "dossier:DalaranQuarantine",
        category = "Dossier",
        caseId = "ARCH-07",
        classification = "Arcane Containment Breach",
        archivist = "Archmage Ansirem Runeweaver",
        title = "Behind the Violet Dome: The Siege Within Dalaran",
        era = "Alterac & Hillsbrad",
        faction = "Contested",
        icon = "Interface\\Icons\\Spell_Arcane_PortalDalaran",
        zones = { "Alterac Mountains", "City of Dalaran", "Hillsbrad Foothills", "Silverpine Forest", "Arathi Highlands" },
        keywords = { "Dalaran", "Kirin Tor", "Ansirem", "Alterac", "Syndicate", "Hillsbrad", "Southshore", "Tarren Mill", "Arcane" },
        summary = "With Dalaran's violet quarantine barrier faltering in the Alterac foothills, rogue warlocks, Syndicate cutthroats, and rampant mana anomalies battle over the ruined magocracy.",
        story = "For years after Archimonde the Defiler crushed Dalaran's towers like sandcastles during the Third War, the surviving magi of the Kirin Tor erected an impenetrable, violet dome over the city's crater along Lordamere Lake. Even allies in nearby Southshore and Ambermill were barred from peering inside while the wizards attempted to purged lingering demonic corruption and rebuild their sanctums.\n\nNow, the protective ward has fractured. Inside the City of Dalaran, wild arcane anomalies roam the shattered avenues, while opportunistic warlocks and Syndicate mercenaries slip through the sewer grates to plunder the forbidden vaults of the Violet Citadel.",
        synthesis = "Archmage Ansirem's field logs reveal why the dome failed: the Kirin Tor attempted to draw ley-line power directly from Lordamere Lake to accelerate reconstruction, inadvertently awakening dormant demonic seals left behind by Archimonde's ritual. If rogue summoners capture the intact spell-vaults beneath Dalaran's streets, they will possess enough concentrated ley energy to obliterate both Southshore and Tarren Mill.",
        leads = "Enter the breached City of Dalaran dungeon in the Alterac Mountains (Levels 28-33) and report findings to Archmage Ansirem Runeweaver.",
        related = { "zone:City of Dalaran", "zone:Alterac Mountains", "zone:Hillsbrad Foothills", "zone:Arathi Highlands", "npc:Archmage Ansirem" },
    },

    -- =====================================================================
    -- 8. THE TITAN ORDERING: WETLANDS, ULDAMAN & SHAPER'S TERRACE
    -- =====================================================================
    {
        key = "dossier:TitanOrdering",
        category = "Dossier",
        caseId = "ARCH-08",
        classification = "Titanic Archaeology & First-Age Matrix",
        archivist = "Prospector Ironboot, Explorers' League",
        title = "The Makers' Blueprint: From Wetlands to Shaper's Terrace",
        era = "First Age of Creation",
        faction = "Neutral",
        icon = "Interface\\Icons\\INV_Misc_StoneTablet_02",
        zones = { "Wetlands", "Excavation Site: Wetlands", "Badlands", "Uldaman", "Un'Goro Crater", "Shaper's Terrace", "Loch Modan", "Tanaris" },
        keywords = { "Titan", "Titans", "Uldaman", "Archaedas", "Norgannon", "Earthen", "Trogg", "Excavation", "Shaper's Terrace", "Un'Goro", "Makers", "Pylon" },
        summary = "Three connected Titan installations—Excavation Site: Wetlands, Uldaman, and Shaper's Terrace in Un'Goro—reveal how the Makers shaped life and why their golems have awakened to purge it.",
        story = "For generations, dwarven myth held that their kind was hammered directly from stone by a benevolent forge-god. That myth shattered in the Badlands when the Explorers' League breached Uldaman, discovering that both dwarves and troggs were mutated Earthen constructs afflicted by the Old Gods' Curse of Flesh. Soon after, Whelgar's diggers in the Wetlands unsealed a deeper subterranean complex—Excavation Site: Wetlands—triggering an ancient automated defense matrix.\n\nAcross the sea in southern Kalimdor, a third and even grander piece of the puzzle stands hidden above the waterfalls of Un'Goro Crater: the Shaper's Terrace, an untouched Titan biosphere control conduit overlooking the crystal pylons of the crater.",
        synthesis = "Translating the rune-conduits across all three sites exposes a single planetary network. When Whelgar's picks breached the Wetlands Excavation Site and adventurers disturbed Archaedas in Uldaman, a fail-safe signal was transmitted across Azeroth's ley lines directly to Shaper's Terrace in Un'Goro. The awakening of celestial automata and biological purifiers in Shaper's Terrace means the Titan network has flagged mortal races as 'corrupted biological anomalies' requiring sterilization.",
        leads = "Investigate Excavation Site: Wetlands (Levels 26-31), recover the Discs of Norgannon from Archaedas in Uldaman (Levels 40-51), and ascend Shaper's Terrace in Un'Goro Crater (Levels 58-60).",
        related = { "zone:Wetlands", "zone:Excavation Site: Wetlands", "zone:Badlands", "zone:Uldaman", "zone:Un'Goro Crater", "zone:Shaper's Terrace", "npc:Archaedas" },
    },

    -- =====================================================================
    -- 9. BLACKROCK MOUNTAIN: THAURISSAN, NEFARIAN & THE DARK HORDE
    -- =====================================================================
    {
        key = "dossier:BlackrockEmpire",
        category = "Dossier",
        caseId = "ARCH-09",
        classification = "Volcanic Superpower & Dragonkin Pact",
        archivist = "Marshal Maxwell & Thorium Brotherhood",
        title = "The Molten Throne: Thaurissan, Nefarian & The Dark Horde",
        era = "Blackrock Mountain",
        faction = "Contested",
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
        zones = { "Searing Gorge", "Burning Steppes", "Redridge Mountains", "Blackrock Depths", "Lower Blackrock Spire", "Upper Blackrock Spire" },
        keywords = { "Blackrock", "Thaurissan", "Ragnaros", "Nefarian", "Rend", "Blackhand", "Drakkisath", "Wyrmthalak", "Moira", "Thorium", "Dark Horde" },
        summary = "Inside the volcanic citadel of Blackrock Mountain, two rival empires—Ragnaros's Dark Iron servants below and Nefarian's Dark Horde above—wage a secret war before turning on Azeroth.",
        story = "Rising between the ash wastes of Searing Gorge and the lava plains of the Burning Steppes, Blackrock Mountain was born in apocalypse when Sorcerer-Thane Thaurissan summoned Ragnaros the Firelord into the world. Today, its hollowed interior houses two colossal military powers locked in a razor's-edge struggle for supremacy.\n\nIn the subterranean metropolis of Blackrock Depths, Emperor Dagran Thaurissan and Princess Moira Bronzebeard rule an enslaved Dark Iron empire forging weapons around the Molten Core. Directly above them, in Lower and Upper Blackrock Spire, Warchief Rend Blackhand and General Drakkisath command the Dark Horde—Blackrock orcs, forest trolls, and ogres serving Deathwing's son, Nefarian.",
        synthesis = "Why haven't the massive armies of Blackrock Mountain swept across Redridge and Stormwind already? Interrogations conducted by the Thorium Brotherhood prove that Ragnaros and Nefarian are actively at war with one another inside the mountain's veins. Every Dark Iron golem forged in the Depths and every chromatic drake bred in the Upper Spire is aimed first at seizing total control of the volcano—and whoever wins that internal war will unleash an unstoppable tide upon the Eastern Kingdoms.",
        leads = "Cut through Searing Gorge and Burning Steppes to breach Blackrock Depths (Levels 52-60), Lower Blackrock Spire (Levels 55-60), and Upper Blackrock Spire (Levels 58-60).",
        related = { "zone:Searing Gorge", "zone:Burning Steppes", "zone:Redridge Mountains", "zone:Blackrock Depths", "zone:Lower Blackrock Spire", "zone:Upper Blackrock Spire", "npc:Emperor Dagran Thaurissan" },
    },

    -- =====================================================================
    -- 10. THE TROLL EMPIRES: DROWNED CITY, SUNKEN TEMPLE & ZUL'FARRAK
    -- =====================================================================
    {
        key = "dossier:GurubashiBloodGod",
        category = "Dossier",
        caseId = "ARCH-10",
        classification = "Ancient Troll Empire & Blood-God Cult",
        archivist = "Exile Zando'zan & Booty Bay Cartel",
        title = "The Sunken Ziggurats: From the Drowned City to Atal'Hakkar",
        era = "Age of the Troll Empires",
        faction = "Contested",
        icon = "Interface\\Icons\\Spell_Nature_Trident",
        zones = { "Stranglethorn Vale", "The Drowned City", "Swamp of Sorrows", "Temple of Atal'Hakkar", "The Hinterlands", "Tanaris", "Zul'Farrak" },
        keywords = { "Gurubashi", "Hakkar", "Atal'ai", "Atal'Hakkar", "Drowned City", "Zul'Farrak", "Sandfury", "Gahz'rilla", "Ukorz", "Vilebranch", "Stranglethorn" },
        summary = "Seismic upheavals off Stranglethorn have raised The Drowned City from the sea floor—reconnecting the blood-cults of the Temple of Atal'Hakkar, Jintha'Alor, and Zul'Farrak.",
        story = "Long before the rise of elves or men, the twin empires of the Gurubashi and Amani trolls ruled the jungles and forests of Azeroth. When the Gurubashi empire fractured in blood-soaked civil war over the worship of Hakkar the Soulflayer, its fanatical Atal'ai priests were driven north into the Swamp of Sorrows, where Ysera's green dragons sank their Temple of Atal'Hakkar beneath the mire.\n\nNow, deep ocean tremors off the southern coast of Stranglethorn Vale have pushed an even older wing of the empire back toward the surface: The Drowned City, a labyrinth of submerged courtyards and air-pocket temples where naga covens and troll zealots clash over resurfaced blood-idols.",
        synthesis = "Relics salvaged from The Drowned City bear the exact sacrificial glyphs carved into the altars of the Temple of Atal'Hakkar, the Vilebranch terraces of the Hinterlands, and the Sandfury pyramid of Zul'Farrak in Tanaris. The Atal'ai did not need to complete their ritual in the Swamp of Sorrows alone—the resurfacing of the Drowned City has restored the ancient coastal ley-triangle used during the original summoning of the Soulflayer.",
        leads = "Dive into The Drowned City off Stranglethorn Vale (Levels 35-40), storm Zul'Farrak in Tanaris (Levels 44-54), and descend into the Temple of Atal'Hakkar in the Swamp of Sorrows (Levels 50-60).",
        related = { "zone:Stranglethorn Vale", "zone:The Drowned City", "zone:Swamp of Sorrows", "zone:Temple of Atal'Hakkar", "zone:The Hinterlands", "zone:Tanaris", "zone:Zul'Farrak" },
    },

    -- =====================================================================
    -- 11. RIVERGLADES & KROL'DOK STRONGHOLD
    -- =====================================================================
    {
        key = "dossier:RivergladesCampaign",
        category = "Dossier",
        caseId = "ARCH-11",
        classification = "Frontier Campaign & Ogre Warlord",
        archivist = "Scout-Captain Vaelen & Farstrider Outriders",
        title = "The Krol'dok Confederacy & The Riverglades Frontier",
        era = "Forever Classic+ Frontier",
        faction = "Contested",
        icon = "Interface\\Icons\\INV_Mace_01",
        zones = { "Riverglades", "Krol'dok Stronghold", "Wetlands", "Arathi Highlands", "Alterac Mountains", "Dustwallow Marsh" },
        keywords = { "Riverglades", "Krol'dok", "Stronghold", "Ogre", "Stromgarde", "Crushridge", "Waterways" },
        summary = "How High Warlord Krol'dok forged a disciplined ogre army equipped with captured siege engines in the lush deltas of the Riverglades.",
        story = "For years, the cascading river deltas and mist-veiled wetlands of the Riverglades served as an untamed natural buffer separating the coastal shipping lanes from the interior highlands. As Alliance timber expeditions and Horde outriders pushed into the basin to secure its rich waterways, they expected scattered bands of primitive ogre squatters.\n\nInstead, they collided with a heavily fortified stone citadel: Krol'dok Stronghold. Under the command of the cunning two-headed tyrant High Warlord Krol'dok, the regional ogre clans have abandoned tribal infighting, organizing into disciplined regiments backed by dark blood-shamanism and captured siege weaponry.",
        synthesis = "Where did an ogre clan in the Riverglades acquire precision dwarven black-powder mortars and refined steel armor? Battlefield inspections around Krol'dok Stronghold indicate that Syndicate arms-dealers from Arathi and Alterac have been secretly supplying Krol'dok's warlords—using the ogre confederacy as a battering ram to bleed both Alliance and Horde supply lines dry across the frontier.",
        leads = "Explore the contested waterways of the Riverglades (Levels 35-45) and lay siege to High Warlord Krol'dok inside Krol'dok Stronghold (Levels 40-45).",
        related = { "zone:Riverglades", "zone:Krol'dok Stronghold", "zone:Wetlands", "zone:Arathi Highlands", "zone:Alterac Mountains", "npc:High Warlord Krol'dok" },
    },

    -- =====================================================================
    -- 12. KARAZHAN, DEADWIND PASS & THE DARK PORTAL
    -- =====================================================================
    {
        key = "dossier:KarazhanEnigma",
        category = "Dossier",
        caseId = "ARCH-12",
        classification = "Ley-Line Singularity & Planar Rift",
        archivist = "Archmage Khadgar's Nethergarde Archives",
        title = "The Ivory Spire of Deadwind & The Dark Portal Rift",
        era = "First War & Aftermath",
        faction = "Contested",
        icon = "Interface\\Icons\\Spell_Shadow_Teleport",
        zones = { "Deadwind Pass", "Blasted Lands", "Duskwood", "Swamp of Sorrows" },
        keywords = { "Karazhan", "Medivh", "Deadwind", "Dark Portal", "Nethergarde", "Blasted Lands", "Guardian" },
        summary = "The necrotic silence of Deadwind Pass and the crimson wastes of the Blasted Lands remain linked by the Last Guardian Medivh's bargain with Sargeras.",
        story = "No bird sings in the howling canyon of Deadwind Pass. At the center of its dead, wind-scoured crags looms the ivory rookery of Karazhan—once the sanctum of Medivh, the Last Guardian of Tirisfal. Possessed from before birth by the spirit of the Dark Titan Sargeras, Medivh collaborated with Gul'dan across the Twisting Nether to tear open the Dark Portal in the Black Morass.\n\nThough Medivh was slain by Khadgar and Anduin Lothar at the climax of the First War, the backlash of his death drained the life from the surrounding valleys, turning the Black Morass into the scorched Blasted Lands and leaving Karazhan warped by temporal echoes.",
        synthesis = "Magical seismographs maintained by Nethergarde Keep in the Blasted Lands show that the dormant Dark Portal rift and the tower of Karazhan act as twin poles of a single dimensional conduit. Every spike of demonic activity near the Dark Portal causes reality inside Deadwind Pass to thin—drawing ghosts, demons, and scavengers to Medivh's sealed library.",
        leads = "Survey the haunted ravines of Deadwind Pass (Levels 55-60) and reinforce the wardens of Nethergarde Keep in the Blasted Lands (Levels 47-55).",
        related = { "zone:Deadwind Pass", "zone:Blasted Lands", "zone:Duskwood", "zone:Swamp of Sorrows" },
    },

    -- =====================================================================
    -- 13. THE SHADOW COUNCIL & RAGEFIRE CHASM
    -- =====================================================================
    {
        key = "dossier:ShadowCouncilHorde",
        category = "Dossier",
        caseId = "ARCH-13",
        classification = "Internal Subversion & Fel Cult",
        archivist = "Neeru Fireblade Surveillance Dossier (Thrall's Kor'kron)",
        title = "Embers in the Cleft: The Shadow Council's Secret War",
        era = "Kalimdor & Durotar",
        faction = "Horde",
        icon = "Interface\\Icons\\Spell_Fire_Volcano",
        zones = { "Durotar", "Ragefire Chasm", "Orgrimmar", "Ashenvale", "Felwood" },
        keywords = { "Ragefire", "Searing Blade", "Shadow Council", "Orgrimmar", "Durotar", "Thrall", "Felwood", "Gul'dan", "Satyr" },
        summary = "Beneath the very streets of Orgrimmar, Searing Blade warlocks in Ragefire Chasm conspire with the Shadow Council cells of Felwood to drag the Horde back into demonic servitude.",
        story = "When Warchief Thrall and Grommash Hellscream freed the orcs from Mannoroth's blood-curse, the newly founded city of Orgrimmar in Durotar was meant to stand as a monument to shamanic rebirth. Yet Thrall permitted warlocks to practice within the dark recesses of the Cleft of Shadows so their movements could be watched.\n\nThat tolerance has been exploited from within. Deep in the magma fissures of Ragefire Chasm beneath Orgrimmar, a cell calling itself the Searing Blade—secretly loyal to the remnants of Gul'dan's Shadow Council—has forged a pact with subterranean troggs and demonic emissaries from Felwood to assassinate Thrall's loyalists and ignite a coup.",
        synthesis = "Letters intercepted between the Cleft of Shadows and Jaedenar in Felwood confirm that the Searing Blade cultists in Ragefire Chasm are funded and directed by the Shadow Council's high command in northern Kalimdor. By corrupting young orc initiates beneath the capital while simultaneously poisoning the forests of Ashenvale and Felwood, the Council seeks to reignite total war between the Horde and the Kaldorei.",
        leads = "Descend into Ragefire Chasm beneath Orgrimmar (Levels 13-18), patrol Durotar (Levels 1-10), and root out the Shadow Council stronghold in Felwood (Levels 48-55).",
        related = { "zone:Durotar", "zone:Ragefire Chasm", "zone:Ashenvale", "zone:Felwood" },
    },

    -- =====================================================================
    -- 14. THE BARRENS: WAILING CAVERNS & THE QUILBOAR LICH-PACT
    -- =====================================================================
    {
        key = "dossier:BarrensFrontier",
        category = "Dossier",
        caseId = "ARCH-14",
        classification = "Emerald Nightmare & Scourge Incursion",
        archivist = "Tonga Runetotem & Crossroads Watch",
        title = "The Fang & The Briar: Wailing Caverns and the Razorfen Pact",
        era = "Central Kalimdor",
        faction = "Horde",
        icon = "Interface\\Icons\\Spell_Nature_AbolishPoison",
        zones = { "The Barrens", "Wailing Caverns", "Razorfen Kraul", "Razorfen Downs", "Mulgore", "Stonetalon Mountains" },
        keywords = { "Barrens", "Crossroads", "Wailing Caverns", "Naralex", "Fang", "Razorfen", "Quilboar", "Charlga", "Amnennar", "Agamaggan", "Mulgore" },
        summary = "Two unnatural blights threatening the heart of the Barrens: the Emerald Nightmare twisting the Wailing Caverns in the north, and a Scourge lich corrupting the Razorfen quilboars in the south.",
        story = "Stretching from the borders of Durotar and Mulgore to the Great Lift of Thousand Needles, The Barrens is the lifeblood of the Horde in Kalimdor. Yet travelers along the Gold Road face far worse than marauding centaurs. In the northern Lushwater Oasis, the night elf druid Naralex entered the underground Wailing Caverns to tap the Emerald Dream and turn the savanna green—only for his subconscious to be trapped by the Nightmare, mutating his disciples into the venomous Druids of the Fang.\n\nMeanwhile, in the colossal thorn-labyrinths of the southern Barrens, the quilboar tribes born from the blood of the ancient boar-god Agamaggan have grown unnaturally aggressive under crone Charlga Razorflank.",
        synthesis = "Why have the quilboars of Razorfen Kraul suddenly launched suicidal assaults across the Barrens? Scouts penetrating the deeper briar-crypts of Razorfen Downs discovered the horrifying truth: Charlga Razorflank brokered an unholy alliance with the Scourge lich Amnennar the Coldbringer. While the Horde's druids are distracted by Naralex's nightmare in the Wailing Caverns, the Lich King has quietly established an undead necropolis right on Mulgore and Durotar's doorstep.",
        leads = "Cleanse the Druids of the Fang to awaken Naralex in Wailing Caverns (Levels 17-24), defeat Charlga Razorflank in Razorfen Kraul (Levels 30-40), and destroy Amnennar the Coldbringer in Razorfen Downs (Levels 37-46).",
        related = { "zone:The Barrens", "zone:Mulgore", "zone:Stonetalon Mountains", "zone:Wailing Caverns", "zone:Razorfen Kraul", "zone:Razorfen Downs", "npc:Naralex" },
    },

    -- =====================================================================
    -- 15. SHEN'DRALAS, DIRE MAUL & THE HIGHBORNE REMNANT
    -- =====================================================================
    {
        key = "dossier:HighborneLegacy",
        category = "Dossier",
        caseId = "ARCH-15",
        classification = "Highborne Arcana & Demon Binding",
        archivist = "Lorekeeper Lydros, Athenaeum of Eldre'Thalas",
        title = "Ghosts of Eldre'Thalas: Shen'Dralas, Dire Maul & The Highborne",
        era = "Kalimdor Highborne",
        faction = "Contested",
        icon = "Interface\\Icons\\Spell_Arcane_ArcaneTorrent",
        zones = { "Shen'Dralas", "Feralas", "Dire Maul", "Desolace", "Mulgore", "Azshara", "Darkshore" },
        keywords = { "Shen'Dralas", "Shen'dralar", "Eldre'Thalas", "Dire Maul", "Tortheldrin", "Highborne", "Gordok", "Feralas", "Immol'thar" },
        summary = "The secret ten-thousand-year survival of Queen Azshara's arcanists in Dire Maul, and why their failing demon-pylons have forced the Highborne into the passes of Shen'Dralas.",
        story = "When the first Well of Eternity imploded during the Great Sundering, Malfurion Stormrage and the Kaldorei outlawed the practice of arcane magic on pain of death. Yet inside the rainforests of Feralas, the proud Highborne caste of Eldre'Thalas—the Shen'dralar—sealed their marble gates against the world. To feed their addiction to magic without the Well, Prince Tortheldrin bound a colossal void-demon named Immol'thar inside the city's West Wing.\n\nFor ten millennia, crystal pylons siphoned the demon's essence. When the demon's power finally waned, Tortheldrin secretly ordered the slaughter of most of his own citizens so a select few could hoard the remaining energy. Today, the ruined metropolis of Dire Maul is split between Tortheldrin's mad court, Gordok ogres, and Warpwood satyrs—while surviving Highborne exiles and arcane anomalies spill out into the rugged highland corridor of Shen'Dralas between Mulgore and Desolace.",
        synthesis = "The sudden emergence of Highborne activity across the Shen'Dralas passes (Levels 45-55) is a direct consequence of the crisis inside Dire Maul. As the crystal pylons holding Immol'thar flicker toward collapse, exiled Shen'dralar scholars are desperately reactivating ancient relay sanctums in the mountains between Mulgore and Desolace—risking an arcane detonation unless Prince Tortheldrin and the demon in Dire Maul are dealt with.",
        leads = "Explore the Highborne ruins of Shen'Dralas (Levels 45-55) and Feralas (Levels 40-50), then breach the East, West, and North wings of Dire Maul (Levels 55-60) to confront Prince Tortheldrin.",
        related = { "zone:Shen'Dralas", "zone:Feralas", "zone:Dire Maul", "zone:Desolace", "zone:Mulgore", "zone:Azshara", "npc:Prince Tortheldrin" },
    },

    -- =====================================================================
    -- 16. MARAUDON, DESOLACE & THE CENTAUR CURSE
    -- =====================================================================
    {
        key = "dossier:CentaurCurse",
        category = "Dossier",
        caseId = "ARCH-16",
        classification = "Elemental Progeny & Cursed Wasteland",
        archivist = "Keeper Marandis, Cenarion Circle",
        title = "Children of the Stonemother: Maraudon & The Desolace Clans",
        era = "Desolace & Maraudon",
        faction = "Contested",
        icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
        zones = { "Desolace", "Maraudon", "Thousand Needles", "The Barrens", "Stonetalon Mountains" },
        keywords = { "Desolace", "Maraudon", "Theradras", "Zaetar", "Centaur", "Kolkar", "Kodo", "Cenarion" },
        summary = "How the forbidden union of Zaetar and Princess Theradras drained a verdant garden into the ash wastes of Desolace and birthed the five warring Centaur clans.",
        story = "Eleven hundred years before the Dark Portal, the central plains of Kalimdor were a lush, verdant paradise tended by Zaetar, immortal son of the demigod Cenarius. Deep beneath the hills, Zaetar encountered Princess Theradras, elemental daughter of Therazane the Stonemother. Their unnatural union produced a barbaric, deformed offspring: the Centaur.\n\nHorrified by his violent children, Zaetar was murdered by his own firstborn khans. Grief-stricken, Princess Theradras entombed Zaetar's spirit within the crystal-laced caverns of Maraudon, which the centaur revere as their sacred temple—while Theradras's subterranean slumber leached every drop of vitality from the surface, turning the region into the bone-strewn wasteland of Desolace.",
        synthesis = "Druidic divinations in Desolace reveal why the Gelkis, Magram, Kolkar, Maraudine, and Galak centaur clans have grown increasingly frenzied. Inside the inner grove of Maraudon, Zaetar's restless spirit is being corrupted by Princess Theradras's grief and the taint of the Emerald Nightmare—poisoning the earth elementals of Kalimdor from within.",
        leads = "Navigate the warring centaur territories of Desolace (Levels 30-40) and Thousand Needles (Levels 30-40), then descend into Maraudon (Levels 46-55) to face Princess Theradras and free Zaetar's spirit.",
        related = { "zone:Desolace", "zone:Maraudon", "zone:Thousand Needles", "zone:The Barrens", "npc:Princess Theradras" },
    },

    -- =====================================================================
    -- 17. BLACKMAW HOLD, FELWOOD & THE DEFENSE OF MOUNT HYJAL
    -- =====================================================================
    {
        key = "dossier:FellwoodBlackmaw",
        category = "Dossier",
        caseId = "ARCH-17",
        classification = "Demonic Blight & World Tree Defense",
        archivist = "Emerald Circle & Timbermaw Emissaries",
        title = "The Tainted Bough: Blackmaw Hold, Felwood & Mount Hyjal",
        era = "Northern Kalimdor",
        faction = "Contested",
        icon = "Interface\\Icons\\Ability_Racial_BearForm",
        zones = { "Azshara", "Blackmaw Hold", "Felwood", "Ashenvale", "Mount Hyjal", "Moonglade", "Teldrassil", "Darkshore" },
        keywords = { "Blackmaw", "Furbolg", "Azshara", "Felwood", "Hyjal", "Nordrassil", "Teldrassil", "Moonglade", "Ashenvale", "Satyr", "Archimonde" },
        summary = "Tracing the lingering demonic corruption from the Skull of Gul'dan in Felwood to the sealed furbolg mountain fortress of Blackmaw Hold in Azshara and the slopes of Mount Hyjal.",
        story = "Although Archimonde the Defiler was obliterated at the summit of Mount Hyjal by the ancestral wisps of Nordrassil, the Burning Legion's invasion left northern Kalimdor deeply scarred. In Felwood, the demonic energies of the Skull of Gul'dan turned ancient groves into slime-choked pools, driving the tranquil furbolg tribes into rabid madness.\n\nMost tragic of all was the fate of the Blackmaw tribe in northern Azshara. Once steadfast allies of the Cenarion Circle and cousins to the Timbermaw, the Blackmaw sealed the massive timber gates of their subterranean mountain city—Blackmaw Hold—to keep the blight out. Instead, they locked the corruption inside with them.",
        synthesis = "Expeditions beyond the northern gate of Azshara into Blackmaw Hold (Levels 55-60) have uncovered why the tribe went silent: demonic agents escaping the defeat at Mount Hyjal tunneled into the mountain roots beneath Azshara, corrupting the Blackmaw chieftains' shamanic totems with fel-blood. Left unchecked, the portal rituals inside Blackmaw Hold will link with the demonic remnants in Darkwhisper Gorge on Mount Hyjal, threatening both Nordrassil and Moonglade.",
        leads = "Cleanse the corrupted groves of Ashenvale (Levels 18-30) and Felwood (Levels 48-55), breach Blackmaw Hold in northern Azshara (Levels 55-60), and stand guard at Mount Hyjal (Level 60) and Moonglade.",
        related = { "zone:Azshara", "zone:Blackmaw Hold", "zone:Felwood", "zone:Ashenvale", "zone:Mount Hyjal", "zone:Moonglade", "zone:Teldrassil", "zone:Darkshore" },
    },

    -- =====================================================================
    -- 18. SILITHUS, UN'GORO & WHISPERS OF THE OLD GODS
    -- =====================================================================
    {
        key = "dossier:SandsOfAhnQiraj",
        category = "Dossier",
        caseId = "ARCH-18",
        classification = "Old God Awakening & Silithid Hives",
        archivist = "Cenarion Hold & Bronze Dragonflight",
        title = "Whispers Beneath the Chitin: Silithus, Tanaris & The Old Gods",
        era = "Southern Kalimdor",
        faction = "Contested",
        icon = "Interface\\Icons\\INV_Misc_AhnQirajTrinket_01",
        zones = { "Silithus", "Un'Goro Crater", "Tanaris", "Thousand Needles", "Feralas", "Ashenvale", "Blackfathom Deeps", "Shaper's Terrace" },
        keywords = { "Silithus", "Ahn'Qiraj", "C'Thun", "Qiraji", "Silithid", "Scarab", "Old God", "Old Gods", "Aku'mai", "Twilight's Hammer", "Tanaris" },
        summary = "From the Twilight's Hammer shrine of Aku'mai in Blackfathom Deeps to the chitinous hives erupting across Tanaris, Un'Goro, and Silithus, an ancient Old God stirs behind the Scarab Wall.",
        story = "A thousand years ago, the Kaldorei and the four Dragonflights fought the brutal War of the Shifting Sands to contain the Qiraji legions pouring out of the desert fortress of Ahn'Qiraj. Unable to destroy the insectoid empire entirely, Archdruid Fandral Staghelm and the Bronze Dragonflight erected the Scarab Wall across southern Silithus, sealing the Qiraji and their dark master within.\n\nNow, the desert floor is trembling once more. Colossal chitinous Silithid hives have erupted not only across Silithus, but deep into Tanaris, the Shimmering Flats, Feralas, and even the Titan biosphere of Un'Goro Crater—while along the Zoram Strand of Ashenvale, Twilight's Hammer cultists worship the Old God hydra Aku'mai inside Blackfathom Deeps.",
        synthesis = "Biological samples gathered from the Gorishi hive in Un'Goro Crater and the Noxious Lair in Tanaris prove that the Silithid are tunneling directly toward Titan ley-conduits like Shaper's Terrace. Behind the Scarab Wall of Silithus, the slumbering Old God C'Thun is using the insectoid hive-mind to weaken the Titanic prison wards holding him beneath Kalimdor.",
        leads = "Purge the Twilight's Hammer from Blackfathom Deeps (Levels 24-32), investigate the Silithid hives in Tanaris (Levels 40-50) and Un'Goro Crater (Levels 48-55), and report to Cenarion Hold in Silithus (Levels 55-60).",
        related = { "zone:Silithus", "zone:Un'Goro Crater", "zone:Tanaris", "zone:Thousand Needles", "zone:Feralas", "zone:Blackfathom Deeps", "zone:Shaper's Terrace" },
    },
}
