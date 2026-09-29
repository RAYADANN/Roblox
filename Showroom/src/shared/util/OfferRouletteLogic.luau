--!strict
-- Pure timing for egg-offer roulette. CI-tested.

local OfferRouletteLogic = {}

export type Config = {
    steps: number?,
    startDelay: number?,
    endDelay: number?,
    padStagger: number?,
}

local DEFAULT_STEPS = 14
local DEFAULT_START = 0.045
local DEFAULT_END = 0.38
local DEFAULT_STAGGER = 0.12

--[[
  Delays between consecutive egg flashes (seconds). Curve eases into a slow finish.
]]
function OfferRouletteLogic.stepDelays(config: Config?): { number }
    local steps = if config and config.steps then config.steps else DEFAULT_STEPS
    local startDelay = if config and config.startDelay then config.startDelay else DEFAULT_START
    local endDelay = if config and config.endDelay then config.endDelay else DEFAULT_END
    steps = math.max(3, math.floor(steps))
    local out: { number } = table.create(steps)
    for i = 1, steps do
        local t = if steps <= 1 then 1 else (i - 1) / (steps - 1)
        -- Ease-in cubic: stay fast early, slow hard near the end.
        local eased = t * t * t
        out[i] = startDelay + (endDelay - startDelay) * eased
    end
    return out
end

function OfferRouletteLogic.padStagger(config: Config?): number
    if config and config.padStagger then
        return config.padStagger
    end
    return DEFAULT_STAGGER
end

function OfferRouletteLogic.totalDuration(
    delays: { number },
    staggerSec: number,
    padIndex: number
): number
    local sum = 0
    for _, d in delays do
        sum += d
    end
    return sum + staggerSec * math.max(0, padIndex - 1)
end

return OfferRouletteLogic
