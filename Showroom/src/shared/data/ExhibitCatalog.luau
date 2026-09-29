--!strict
-- Catalog of exhibit base forms (MVP: cube styles). Visual ids only — no Instance API.

export type StyleId = "cube_teal" | "cube_amber" | "cube_violet" | "cube_rose" | "cube_mint"
export type CharacterId = "calm" | "curious" | "bold" | "shy" | "spark"

export type ExhibitTemplate = {
    templateId: string,
    styleId: StyleId,
    characterId: CharacterId,
    displayName: string,
    colorRgb: { number }, -- 0–255
}

local TEMPLATES: { ExhibitTemplate } = {
    {
        templateId = "orb_teal",
        styleId = "cube_teal",
        characterId = "calm",
        displayName = "Teal Orb",
        colorRgb = { 55, 180, 160 },
    },
    {
        templateId = "orb_amber",
        styleId = "cube_amber",
        characterId = "curious",
        displayName = "Amber Chunk",
        colorRgb = { 230, 160, 60 },
    },
    {
        templateId = "orb_violet",
        styleId = "cube_violet",
        characterId = "bold",
        displayName = "Violet Shard",
        colorRgb = { 140, 90, 220 },
    },
    {
        templateId = "orb_rose",
        styleId = "cube_rose",
        characterId = "shy",
        displayName = "Rose Relic",
        colorRgb = { 220, 90, 130 },
    },
    {
        templateId = "orb_mint",
        styleId = "cube_mint",
        characterId = "spark",
        displayName = "Mint Orb",
        colorRgb = { 80, 210, 150 },
    },
}

local byId: { [string]: ExhibitTemplate } = {}
for _, t in TEMPLATES do
    byId[t.templateId] = t
end

return {
    TEMPLATES = TEMPLATES,
    byId = byId,
    SLOT_COUNT = 6,
    OFFER_COUNT = 3,
    HIGHLIGHT_T_START = 0,
    HIGHLIGHT_T_END = 0.85,
    REACT_ATTENTION = 4,
    REACT_COOLDOWN_SEC = 2.5,
    INCOME_TICK_SEC = 0.5,
    DISPENSER_REFRESH_SEC = 12,
}
