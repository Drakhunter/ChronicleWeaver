local addonName, ns = ...

ns.LoreEntries = {
    -- ==========================================
    -- ZONES & FOREVER DUNGEONS
    -- ==========================================
    {
        key = "zone:Hall of Thanes",
        category = "Dungeon",
        faction = "Alliance",
        triggerType = "ZONE",
        triggerValue = "Hall of Thanes",
        title = "The Hall of Thanes (Levels 13 18)",
        era = "Forever Classic+",
        summary = "Ancient royal burial chambers beneath Old Ironforge disturbed by Dark Iron infiltrators.",
        story = "Carved deep into the living stone beneath Ironforge, the Hall of Thanes holds the honored tombs of Bronzebeard and Anvilmar monarchs from before the War of the Three Hammers. Recently, Dark Iron saboteurs led by Durgen Dirgehammer breached the lower vaults, awakening elemental guardians and unsettling the spirits of the ancient dwarven kings.",
        related = { "npc:Faldrim Anvilmar", "npc:Durgen Dirgehammer" },
    },
    {
        key = "zone:Ruins of Lordaeron",
        category = "Dungeon",
        faction = "Horde",
        triggerType = "ZONE",
        triggerValue = "Ruins of Lordaeron",
        title = "Ruins of Lordaeron (Levels 15 20)",
        era = "Forever Classic+",
        summary = "The shattered surface palace of Capital City, contested by Forsaken reclaimers and lingering Scourge.",
        story = "Above the labyrinthine Undercity stand the haunted gardens and collapsed throne room where Prince Arthas Menethil murdered King Terenas II. As Sylvanas Windrunner consolidates Forsaken control over Tirisfal, expeditions into the upper ruins face remnants of the Scourge and zealous Scarlet holdouts.",
        related = {},
    },
    {
        key = "zone:Zephras Isle",
        category = "Zone",
        faction = "Neutral",
        triggerType = "ZONE",
        triggerValue = "Zephras Isle",
        title = "Zephras Isle & The Skyborne",
        era = "Forever Classic+",
        summary = "A wind-swept sanctuary shrouded in storm clouds and ancient elemental pacts.",
        story = "Long hidden from the nautical charts of Kul Tiras and Stormwind, Zephras Isle is home to the Skyborne and the Windshapers. Here, ancient air shrines channel the tempests of the Great Sea, drawing scholars and adventurers seeking forgotten elemental lore.",
        related = {},
    },
    {
        key = "zone:Ironforge",
        category = "Zone",
        faction = "Alliance",
        triggerType = "ZONE",
        triggerValue = "Ironforge",
        title = "The Great Forge of Khaz Modan",
        era = "Classic & Forever",
        summary = "Ancestral mountain capital of the Bronzebeard Dwarves under King Magni Bronzebeard.",
        story = "Hollowed out of the heart of Dun Morogh, Ironforge survived both the Second War siege by the Blackrock clan and the fracturing of the three dwarven clans. Beneath its bustling Commons and Mystic Ward lie sealed doors leading down to Old Ironforge and the sacred Hall of Thanes.",
        related = { "zone:Hall of Thanes" },
    },

    -- ==========================================
    -- NPCS & FOREVER BOSSES
    -- ==========================================
    {
        key = "npc:Faldrim Anvilmar",
        category = "NPC",
        faction = "Alliance",
        triggerType = "NPC",
        triggerValue = "Faldrim Anvilmar",
        title = "Thane Faldrim Anvilmar",
        era = "Forever Classic+",
        summary = "Restless undead ancestor patrolling his desecrated tomb in the Hall of Thanes.",
        story = "A scion of the royal Anvilmar bloodline laid to rest centuries ago. When Dark Iron looters cracked the protective runes of the West Wing in the Hall of Thanes, Faldrim's spirit was bound back to his ossified remains, cursing any intruder who steps near his sarcophagus with petrifying stone.",
        related = { "zone:Hall of Thanes", "npc:Durgen Dirgehammer" },
    },
    {
        key = "npc:Durgen Dirgehammer",
        category = "NPC",
        faction = "Alliance",
        triggerType = "NPC",
        triggerValue = "Durgen Dirgehammer",
        title = "Overseer Durgen Dirgehammer",
        era = "Forever Classic+",
        summary = "Architect of the Dark Iron incursion beneath Old Ironforge.",
        story = "Dispatched from Blackrock Depths with a detachment of Dark Iron Summoners, Engineers, and Lesser Stone Golems, Dirgehammer seeks ancient royal charters and relics buried with the early High Kings to undermine Magni Bronzebeard's legitimacy.",
        related = { "zone:Hall of Thanes", "npc:Faldrim Anvilmar" },
    },
    {
        key = "npc:Edwin VanCleef",
        category = "NPC",
        faction = "Alliance",
        triggerType = "NPC",
        triggerValue = "Edwin VanCleef",
        title = "Edwin VanCleef, Leader of the Defias",
        era = "Classic & Forever",
        summary = "Master architect of Stormwind turned revolutionary outlaw in the Deadmines.",
        story = "After rebuilding Stormwind City following the First War, the Stonemasons Guild was refused payment by a House of Nobles manipulated by Lady Katrana Prestor. VanCleef led the cheated artisans into Westfall, founding the Defias Brotherhood and constructing a juggernaut warship inside the Deadmines.",
        related = {},
    },

    -- ==========================================
    -- ITEMS & RELICS
    -- ==========================================
    {
        key = "item:6948",
        category = "Relic",
        faction = "Neutral",
        triggerType = "ITEM",
        triggerValue = 6948, -- Hearthstone (great for instant testing in-game!)
        title = "The Innkeeper's Hearthstone",
        era = "Classic & Forever",
        summary = "A rune-carved stone attuned to the ley-warmth of a chosen hearth.",
        story = "Originally enchanted by Kirin Tor geomancers and adopted by tavern keepers across Azeroth, a Hearthstone binds to the ambient arcane signature of a resting place, pulling its bearer back through the twisting ley paths in times of need.",
        related = {},
    },

    -- ==========================================
    -- CLUE SYNTHESIS & DEDUCTIONS (Step 3.1)
    -- ==========================================
    {
        key = "synth:DarkIronConspiracy",
        category = "Deduction",
        faction = "Alliance",
        triggerType = "SYNTHESIS",
        requiredClues = { "zone:Hall of Thanes", "npc:Faldrim Anvilmar", "npc:Durgen Dirgehammer" },
        title = "The Desecration of Old Ironforge",
        era = "Deduction",
        summary = "Uncovering the true objective behind the Dark Iron infiltrators beneath Old Ironforge.",
        story = "By connecting the desecrated burial vaults in the Hall of Thanes with the restless ghost of Thane Faldrim Anvilmar and the presence of Overseer Durgen Dirgehammer, a sinister plot emerges: the Dark Iron clan is not merely sabotaging Ironforge's foundations they are searching for the lost Crown of the High King to assert rightful claim over all three dwarven clans.",
        related = { "zone:Hall of Thanes", "npc:Faldrim Anvilmar", "npc:Durgen Dirgehammer" },
    },
    {
        key = "synth:DefiasAndNobles",
        category = "Deduction",
        faction = "Alliance",
        triggerType = "SYNTHESIS",
        requiredClues = { "zone:Ironforge", "npc:Edwin VanCleef" },
        title = "The Stonemasons & The Dragon's Web",
        era = "Deduction",
        summary = "How the reconstruction of human kingdoms spurred civil rebellion and hidden draconic subversion.",
        story = "Comparing the grand masonry of the Great Forge with Edwin VanCleef's history reveals the tragic betrayal of the Stonemasons Guild: nobles influenced by draconic manipulation refused payment for the reconstruction of Stormwind, driving royal architects into the shadows of Westfall to forge a revolutionary army.",
        related = { "zone:Ironforge", "npc:Edwin VanCleef" },
    },
}

-- Build fast lookup dictionaries on ADDON_LOADED
function ns.BuildLoreIndex()
    ns.LoreByKey = {}
    ns.LoreByZone = {}
    ns.LoreByNPC = {}
    ns.LoreByItem = {}
    ns.LoreSyntheses = {}

    for _, entry in ipairs(ns.LoreEntries) do
        ns.LoreByKey[entry.key] = entry
        if entry.triggerType == "ZONE" then
            ns.LoreByZone[entry.triggerValue:lower()] = entry.key
        elseif entry.triggerType == "NPC" then
            ns.LoreByNPC[entry.triggerValue:lower()] = entry.key
        elseif entry.triggerType == "ITEM" then
            ns.LoreByItem[entry.triggerValue] = entry.key
        elseif entry.triggerType == "SYNTHESIS" then
            table.insert(ns.LoreSyntheses, entry)
        end
    end
end
