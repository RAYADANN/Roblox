--!strict
-- Pure Mutation text shine step (lab V1–V5). CI-tested. No Roblox types.

export type Offset = { x: number, y: number }

export type ShinePose = {
    offset: Offset,
    rotation: number,
}

local ZERO: Offset = { x = 0, y = 0 }

local MutationShineLogic = {}

--- variant 0 = static (no motion). 1–5 = lab picks.
function MutationShineLogic.pose(variant: number, t: number, baseRotation: number): ShinePose
    local base = baseRotation
    if variant <= 0 then
        return { offset = ZERO, rotation = base }
    end
    if variant == 1 then
        local cycle = (t % 1.6) / 1.6
        return { offset = { x = cycle * 2 - 1, y = 0 }, rotation = base }
    end
    if variant == 2 then
        return { offset = { x = math.sin(t * 1.4) * 0.85, y = 0 }, rotation = base }
    end
    if variant == 3 then
        return { offset = ZERO, rotation = (base + t * 90) % 360 }
    end
    if variant == 4 then
        local cycle = (t % 1.8) / 1.8
        return {
            offset = { x = cycle * 2 - 1, y = 0 },
            rotation = base + math.sin(t * 2.2) * 18,
        }
    end
    return {
        offset = { x = math.sin(t * 4.5) * 0.55, y = math.cos(t * 3.2) * 0.15 },
        rotation = base + math.sin(t * 5) * 8,
    }
end

return MutationShineLogic
