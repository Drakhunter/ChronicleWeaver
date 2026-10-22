-- =========================================================================
-- Data/Lore_Classic.lua
-- Curated Classic Azeroth Zones, Dungeons, Bosses & Relics.
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

ns.RawLoreClassic = {
    -- ==========================================
    -- ZONES
    -- ==========================================
    {
        key = "zone:Ironforge",
        category = "Zone",
        zone = "Ironforge",
        triggerType = "ZONE",
        triggerValue = "Ironforge",
        title = "Ironforge: The Great Forge",
        era = "Classic",
        faction = "Alliance",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        summary = "Ancestral mountain capital of the Bronzebeard Dwarves under King Magni Bronzebeard.",
        story = "Hollowed out of the heart of Dun Morogh, Ironforge survived both the Second War siege by the Blackrock clan and the fracturing of the three dwarven clans. Beneath its bustling Commons and Mystic Ward lie sealed doors leading down to Old Ironforge and the sacred Hall of Thanes.",
        related = { "zone:Hall of Thanes", "npc:Faldrim Anvilmar", "dossier:ThreeHammers" },
        mapID = 1455,
        x = 0.50,
        y = 0.50,
    },
    {
        key = "zone:Westfall",
        category = "Zone",
        zone = "Westfall",
        triggerType = "ZONE",
        triggerValue = "Westfall",
        title = "Westfall: The Dust Plains",
        era = "Classic",
        faction = "Alliance",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        summary = "Once the breadbasket of Stormwind, now a lawless wasteland overrun by bandits and rogue harvest reapers.",
        story = "Following the Stonemason riot in Stormwind, the kingdom withdrew its garrisons from Westfall, leaving the farmers to defend themselves against the encroaching Defias Brotherhood and hungry gnoll packs from the Redridge border.",
        related = { "npc:Edwin VanCleef", "dossier:DefiasConspiracy" },
        mapID = 1436,
        x = 0.56,
        y = 0.52,
    },
    {
        key = "zone:Silverpine Forest",
        category = "Zone",
        zone = "Silverpine Forest",
        triggerType = "ZONE",
        triggerValue = "Silverpine Forest",
        title = "Silverpine Forest",
        era = "Classic",
        faction = "Horde",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        summary = "Fog-laden forests south of Tirisfal Glades, stalked by Arugal's worgen and Scourge remnants.",
        story = "Stretching along the coast of the Great Sea down to the Greymane Wall, Silverpine was once a tranquil timberland of the Kingdom of Lordaeron. Today, perpetual gloom hangs over the pine canopy, where Forsaken Deathstalkers wage a desperate shadow war against feral worgen packs.",
        related = { "npc:Archmage Arugal", "dossier:SilverpineCurse" },
        mapID = 1421,
        x = 0.45,
        y = 0.40,
    },

    -- ==========================================
    -- NPCS & NOTABLE FIGURES
    -- ==========================================
    {
        key = "npc:Edwin VanCleef",
        category = "NPC",
        zone = "Westfall",
        triggerType = "NPC",
        triggerValue = "Edwin VanCleef",
        title = "Edwin VanCleef, Defias Kingpin",
        era = "Classic",
        faction = "Alliance",
        icon = "Interface\\Icons\\INV_Helmet_47",
        summary = "Master architect of Stormwind turned revolutionary outlaw in the Deadmines.",
        story = "After rebuilding Stormwind City following the First War, the Stonemasons Guild was refused payment by a House of Nobles manipulated by Lady Katrana Prestor. VanCleef led the cheated artisans into Westfall, founding the Defias Brotherhood and constructing a juggernaut warship inside the Deadmines.",
        related = { "zone:Westfall", "dossier:DefiasConspiracy" },
        mapID = 1436,
        x = 0.42,
        y = 0.72,
    },
    {
        key = "npc:Archmage Arugal",
        category = "NPC",
        zone = "Silverpine Forest",
        triggerType = "NPC",
        triggerValue = "Archmage Arugal",
        title = "Archmage Arugal",
        era = "Classic",
        faction = "Neutral",
        icon = "Interface\\Icons\\Spell_Shadow_GatherShadows",
        summary = "Former Kirin Tor wizard driven mad by the extraplanar Worgen he summoned.",
        story = "Desperate to defend Dalaran and Gilneas from the Scourge during the Third War, Arugal adopted the forbidden research of Ur, summoning vicious wolf-men from another dimension. Overcome by grief and madness when the beasts turned on his people, Arugal retreated to Shadowfang Keep, adopting the ravenous pack as his 'children'.",
        related = { "zone:Silverpine Forest", "dossier:SilverpineCurse" },
        mapID = 1421,
        x = 0.44,
        y = 0.67,
    },

    -- ==========================================
    -- RELICS
    -- ==========================================
    {
        key = "item:6948",
        category = "Relic",
        zone = "Azeroth",
        triggerType = "ITEM",
        triggerValue = 6948,
        itemID = 6948,
        title = "The Innkeeper's Hearthstone",
        era = "Classic",
        faction = "Neutral",
        icon = "Interface\\Icons\\INV_Misc_Rune_01",
        summary = "A rune-carved stone attuned to the ley-warmth of a chosen hearth.",
        story = "Originally enchanted by Kirin Tor geomancers and adopted by tavern keepers across Azeroth, a Hearthstone binds to the ambient arcane signature of a resting place, pulling its bearer back through the twisting ley paths in times of need.",
        related = {},
    },
}
