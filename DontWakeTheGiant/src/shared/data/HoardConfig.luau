--!strict
-- Кольца сокровищницы (GDD 2.5). Шансы в процентах, сумма каждого кольца = 100.

export type RingDef = {
    respawnSec: number,
    chances: { [string]: number },
    count: number,
    minRadius: number,
    maxRadius: number,
}

local HoardConfig = {}

HoardConfig.RINGS = {
    Outer = {
        respawnSec = 8,
        count = 24,
        minRadius = 90,
        maxRadius = 140,
        chances = { Common = 80, Uncommon = 20 },
    },
    Middle = {
        respawnSec = 15,
        count = 16,
        minRadius = 50,
        maxRadius = 90,
        chances = { Uncommon = 50, Rare = 40, Epic = 10 },
    },
    Inner = {
        respawnSec = 30,
        count = 8,
        minRadius = 0,
        maxRadius = 50,
        chances = { Rare = 40, Epic = 42, Legendary = 16, Mythic = 2 },
    },
    Hand = {
        respawnSec = 180,
        count = 1,
        minRadius = 0,
        maxRadius = 0,
        chances = { Legendary = 85, Mythic = 15 },
    },
    -- Teddy: респаун отсчитывается после доставки мишки (GDD 2.5, 5.10).
    Teddy = {
        respawnSec = 600,
        count = 1,
        minRadius = 0,
        maxRadius = 0,
        chances = { Secret = 100 },
    },
} :: { [string]: RingDef }

-- Бесхозный предмет лежит в точке поимки, потом возвращается домой (GDD 2.4).
HoardConfig.DROPPED_LIFETIME_SEC = 20

-- Мишку можно взять только при тихом великане (GDD 5.10).
HoardConfig.TEDDY_MAX_NOISE = 20

return HoardConfig
