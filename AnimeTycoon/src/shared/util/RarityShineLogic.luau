--!strict
-- Pure Rarity text shine poses (R1–R8). Distinct from MutationShineLogic (V1–V5).
-- No Roblox types (Lune CI).

export type Offset = { x: number, y: number }

export type ShinePose = {
    offset: Offset,
    rotation: number,
    --- mid-keypoint transparency 0..1 (optional pulse); nil = leave alone
    midTransparency: number?,
}

local ZERO: Offset = { x = 0, y = 0 }

local function pingPong(t: number, period: number): number
    local u = (t % period) / period
    if u < 0.5 then
        return u * 2
    end
    return 1 - (u - 0.5) * 2
end

local RarityShineLogic = {}

--- variant 0 = static. 1–8 = rarity lab (not mutation V-set).
function RarityShineLogic.pose(variant: number, t: number, baseRotation: number): ShinePose
    local base = baseRotation
    if variant <= 0 then
        return { offset = ZERO, rotation = base }
    end

    if variant == 1 then
        local cycle = (t % 1.7) / 1.7
        return { offset = { x = 0, y = cycle * 2 - 1 }, rotation = base }
    end
    if variant == 2 then
        return {
            offset = ZERO,
            rotation = base + math.sin(t * 1.8) * 28,
        }
    end
    if variant == 3 then
        local a = 0.55
        return {
            offset = { x = math.cos(t * 2.1) * a, y = math.sin(t * 2.1) * a },
            rotation = base,
        }
    end
    if variant == 4 then
        return {
            offset = { x = 0, y = math.sin(t * 1.1) * 0.4 },
            rotation = base + math.sin(t * 1.1) * 6,
            midTransparency = 0.08 + (math.sin(t * 1.1) * 0.5 + 0.5) * 0.22,
        }
    end
    if variant == 5 then
        local p = pingPong(t, 2.0)
        return { offset = { x = p * 2 - 1, y = 0 }, rotation = base }
    end
    if variant == 6 then
        local s = math.sin(t * 1.35)
        return { offset = { x = s * 0.7, y = s * 0.7 }, rotation = base }
    end
    if variant == 7 then
        local pulse = math.sin(t * 2.6) * 0.5 + 0.5
        return {
            offset = { x = 0, y = math.sin(t * 0.9) * 0.2 },
            rotation = base,
            midTransparency = 0.05 + pulse * 0.45,
        }
    end
    local saw = (t % 0.85) / 0.85
    return {
        offset = { x = saw * 2 - 1, y = math.sin(t * 8) * 0.12 },
        rotation = base + (if saw < 0.08 then 12 else 0),
        midTransparency = if saw < 0.12 then 0.35 else 0.05,
    }
end

return RarityShineLogic
