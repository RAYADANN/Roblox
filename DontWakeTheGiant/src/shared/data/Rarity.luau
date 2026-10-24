--!strict
-- Редкости: порядок, цвета (GDD 3.1), шум взятия (2.2), свет в сокровищнице (5.1).

export type RarityId = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

export type RarityDef = {
    order: number,
    color: Color3,
    grabNoise: number,
    lightRange: number,
}

local Rarity = {}

Rarity.ORDER =
    { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" } :: { RarityId }

Rarity.DEFS = {
    Common = { order = 1, color = Color3.fromHex("#B4B4B4"), grabNoise = 3, lightRange = 0 },
    Uncommon = { order = 2, color = Color3.fromHex("#4CD964"), grabNoise = 5, lightRange = 0 },
    Rare = { order = 3, color = Color3.fromHex("#3B9CFF"), grabNoise = 8, lightRange = 8 },
    Epic = { order = 4, color = Color3.fromHex("#A259FF"), grabNoise = 12, lightRange = 12 },
    Legendary = { order = 5, color = Color3.fromHex("#FFC93C"), grabNoise = 18, lightRange = 16 },
    Mythic = { order = 6, color = Color3.fromHex("#FF3D7F"), grabNoise = 25, lightRange = 22 },
    -- Secret: взятие сразу поднимает шум до максимума (см. GiantConfig.NOISE_MAX).
    Secret = {
        order = 7,
        color = Color3.fromHex("#FFFFFF"),
        grabNoise = math.huge,
        lightRange = 22,
    },
} :: { [RarityId]: RarityDef }

return Rarity
