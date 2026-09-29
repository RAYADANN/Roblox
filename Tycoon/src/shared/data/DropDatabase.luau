--!strict

-- Kind `value` multiplies dummy-tier base from Constants.DROP_TIER_*. Lucky is 0.

export type DropKind = "normal" | "gold" | "shiny" | "diamond" | "lucky"

export type DropEntry = {
    value: number,
    r: number,
    g: number,
    b: number,
}

local DropDatabase: { [DropKind]: DropEntry } = {
    normal = { value = 1, r = 245, g = 245, b = 230 },
    gold = { value = 3, r = 255, g = 196, b = 48 },
    shiny = { value = 5, r = 220, g = 90, b = 255 },
    diamond = { value = 10, r = 80, g = 210, b = 255 },
    lucky = { value = 0, r = 255, g = 120, b = 40 },
}

return DropDatabase
