--!strict
-- Hero pools by rarity. Names match GameAssets.Heroes/<Rarity> models.
-- More popular brainrot → higher rarity (content contract).

local RarityDatabase
if script and script.Parent then
    RarityDatabase = require(script.Parent.RarityDatabase)
else
    RarityDatabase = require("./RarityDatabase")
end

export type RarityId = RarityDatabase.RarityId

local POOLS: { [RarityId]: { string } } = {
    mythic = {
        "Tralalero Tralala",
        "Bombardiro Crocodilo",
        "Cappuccino Assassino",
        "Brr Brr Patapim",
        "Ta Ta Ta Ta Sahur",
        "Los Tungtungtungcitos",
        "Lirilì Larilà",
        "Trippi Troppi",
        "La_Vacca_Saturno_Saturnita",
        "Brainrot God Lucky Block",
    },
    legendary = {
        "Orcalero Orcala",
        "Bombombini Gusini",
        "Spioniro Golubiro",
        "Dragon Cannelloni",
        "Pot Hotspot",
        "Garama_and_Madundung",
        "La_Grande_Combinasion",
        "Trippi Troppi Troppa Trippa",
        "Nuclearo Dinossauro",
        "Trenostruzzo_Turbo_3000",
        "Graipuss Medussi",
        "Secret Lucky Block",
        "Mythic Lucky Block",
        "Piccione Macchina",
        "Frigo Camelo",
        "Cocofanto Elefanto",
    },
    rare = {
        "Cavallo_Virtuoso",
        "Las Tralaleritas",
        "Boneca Ambalabu",
        "Los Boneca_AmbalabuDouble dicen BONECAA",
        "Torrtuginni Dragonfrutini",
        "Girafa_Celestre",
        "Glorbo Fruttodrillo",
        "Gorillo Watermelondrillo",
        "Chicleteira Bicicleteira",
        "Statutino Libertino",
        "Espresso Signora",
        "Sammyni_Spyderini",
        "Chimpanzini Spiderini",
        "Agarrini la Palini",
        "Gangster Footera",
        "Avocadorilla",
        "Tigroligre Frutonni",
        "Zibra Zubra Zibralini",
    },
    uncommon = {
        "Tigrilini Watermelini",
        "Pandaccini Bananini",
        "Lionel_Cactuseli",
        "Pi Pi Watermelon",
        "Burbaloni Loliloli",
        "Perochello_Lemonchello",
        "Tukanno Bananno",
        "Gattatino Neonino",
        "Gattatino_Nyanino",
        "Bananita Dolphinita",
        "Strawberrelli Flamingelli",
        "Blueberrinni_Octopusini",
        "Trulimero Trulicina",
        "Bandito_Bobritto",
        "Salamino Penguino",
        "Svinina Bombardino",
        "Tim Cheese",
        "Cacto Hipopotamo",
    },
    common = {
        "Pipi_Kiwi",
        "Avocadini Guffo",
        "Tric_Trac_Baraboom",
        "Ganganzelli Trulala",
        "Cocosini Mama",
        "Sigma Boy",
        "Pipi Avocado",
        "Bambini_Crostini",
        "Penguino Cocosino",
    },
}

-- Folder names under Workspace.Герои (Studio uses Uncomon typo for uncommon UI, but Герои uses Uncommon).
local FOLDER_BY_RARITY: { [RarityId]: string } = {
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    legendary = "Legendary",
    mythic = "Mythic",
}

local HeroCatalog = {}

--- Player-facing name: underscores → spaces, drop "Brainrot", tidy whitespace.
function HeroCatalog.displayName(heroId: string): string
    if typeof(heroId) ~= "string" or heroId == "" then
        return ""
    end
    local s = heroId
    s = string.gsub(s, "_", " ")
    -- Remove Brainrot as whole word (any case), keep Lucky Block etc.
    s = string.gsub(s, "[Bb][Rr][Aa][Ii][Nn][Rr][Oo][Tt]", "")
    s = string.gsub(s, "%s+", " ")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

function HeroCatalog.pool(rarity: string): { string }
    local id = rarity :: RarityId
    return POOLS[id] or POOLS.common
end

function HeroCatalog.folderName(rarity: string): string
    local id = rarity :: RarityId
    return FOLDER_BY_RARITY[id] or "Common"
end

function HeroCatalog.fallbackHeroId(): string
    return "Pipi_Kiwi"
end

return HeroCatalog
