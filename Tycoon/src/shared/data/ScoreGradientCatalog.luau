--!strict
-- Vertical score/UI gradients. All entries use the same stop proportions:
-- t = 0 (top/light) → 0.5 (mid) → 1 (bottom/dark).

export type Rgb = { r: number, g: number, b: number }

export type GradientStop = {
    t: number,
    c: Rgb,
}

export type GradientDef = {
    id: string,
    source: string,
    stops: { GradientStop },
}

local function rgb(r: number, g: number, b: number): Rgb
    return { r = r, g = g, b = b }
end

local function vertical(id: string, source: string, top: Rgb, mid: Rgb, bottom: Rgb): GradientDef
    return {
        id = id,
        source = source,
        stops = {
            { t = 0, c = top },
            { t = 0.5, c = mid },
            { t = 1, c = bottom },
        },
    }
end

-- Collected from theme / VFX LayerRunner / brand, plus extras for score pops.
local ScoreGradientCatalog: { GradientDef } = {
    -- theme.Colors gold
    vertical("gold", "theme.Colors.gold", rgb(255, 238, 130), rgb(255, 212, 38), rgb(160, 90, 10)),
    -- theme.Rarity
    vertical(
        "rare_blue",
        "theme.Rarity.rare",
        rgb(180, 220, 255),
        rgb(80, 160, 255),
        rgb(20, 50, 140)
    ),
    vertical(
        "epic_purple",
        "theme.Rarity.epic",
        rgb(230, 190, 255),
        rgb(180, 100, 255),
        rgb(70, 20, 120)
    ),
    vertical(
        "legendary",
        "theme.Rarity.legendary",
        rgb(255, 240, 160),
        rgb(255, 180, 40),
        rgb(140, 70, 0)
    ),
    vertical(
        "mythic",
        "theme.Rarity.mythic",
        rgb(255, 180, 200),
        rgb(255, 80, 120),
        rgb(120, 10, 40)
    ),
    vertical(
        "uncommon",
        "theme.Rarity.uncommon",
        rgb(180, 255, 200),
        rgb(80, 200, 120),
        rgb(20, 90, 50)
    ),
    -- LayerRunner fire / plasma / ember (resampled to 0 / 0.5 / 1)
    vertical("vfx_fire", "LayerRunner.fire", rgb(255, 255, 220), rgb(255, 100, 30), rgb(80, 20, 5)),
    vertical(
        "vfx_plasma",
        "LayerRunner.plasma",
        rgb(255, 255, 255),
        rgb(160, 140, 255),
        rgb(20, 10, 40)
    ),
    vertical(
        "vfx_ember",
        "LayerRunner.ember",
        rgb(255, 220, 120),
        rgb(255, 100, 30),
        rgb(80, 20, 5)
    ),
    -- brand cyan → purple
    vertical(
        "brand_cyan_purple",
        "brand Z",
        rgb(120, 255, 255),
        rgb(100, 140, 255),
        rgb(140, 40, 200)
    ),
    -- drop kinds
    vertical(
        "drop_shiny",
        "DropDatabase.shiny",
        rgb(255, 200, 255),
        rgb(220, 90, 255),
        rgb(90, 20, 140)
    ),
    vertical(
        "drop_diamond",
        "DropDatabase.diamond",
        rgb(200, 255, 255),
        rgb(80, 210, 255),
        rgb(20, 80, 140)
    ),
    vertical(
        "drop_gold",
        "DropDatabase.gold",
        rgb(255, 240, 160),
        rgb(255, 196, 48),
        rgb(150, 90, 0)
    ),
    -- extras for score variety
    vertical("sunset", "score.extra", rgb(255, 230, 180), rgb(255, 120, 60), rgb(120, 30, 60)),
    vertical("lime", "score.extra", rgb(230, 255, 160), rgb(140, 220, 40), rgb(40, 100, 10)),
    vertical("ice", "score.extra", rgb(255, 255, 255), rgb(140, 220, 255), rgb(40, 80, 160)),
    vertical("magma", "score.extra", rgb(255, 200, 80), rgb(255, 60, 20), rgb(60, 10, 10)),
    vertical("candy", "score.extra", rgb(255, 200, 240), rgb(255, 100, 180), rgb(120, 20, 100)),
    vertical("mint", "score.extra", rgb(220, 255, 240), rgb(60, 220, 180), rgb(10, 90, 80)),
    vertical("amber", "score.extra", rgb(255, 245, 200), rgb(255, 170, 40), rgb(130, 60, 0)),
}

local byId: { [string]: GradientDef } = {}
for _, def in ScoreGradientCatalog do
    byId[def.id] = def
end

local ScoreGradientCatalogApi = {}

function ScoreGradientCatalogApi.all(): { GradientDef }
    return ScoreGradientCatalog
end

function ScoreGradientCatalogApi.get(id: string): GradientDef?
    return byId[id]
end

function ScoreGradientCatalogApi.count(): number
    return #ScoreGradientCatalog
end

--- Stable pick by index (wraps). Use for random / rotating pops.
function ScoreGradientCatalogApi.at(index: number): GradientDef
    local n = #ScoreGradientCatalog
    local i = ((math.floor(index) - 1) % n) + 1
    return ScoreGradientCatalog[i]
end

--- Random catalog entry. Optional rng() returns [0,1) for tests.
function ScoreGradientCatalogApi.random(rng: (() -> number)?): GradientDef
    local roll = if rng then rng() else math.random()
    local n = #ScoreGradientCatalog
    local index = math.clamp(math.floor(roll * n) + 1, 1, n)
    return ScoreGradientCatalog[index]
end

return ScoreGradientCatalogApi
