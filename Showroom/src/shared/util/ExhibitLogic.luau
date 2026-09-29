--!strict
-- Pure: evolve duration, income curve, NPC crowd roll, highlight fade, anim pick.
-- CI-tested.

local RarityDatabase
local ExhibitCatalog
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
    ExhibitCatalog = require(script.Parent.Parent.data.ExhibitCatalog)
else
    RarityDatabase = require("../data/RarityDatabase")
    ExhibitCatalog = require("../data/ExhibitCatalog")
end

export type RarityId = RarityDatabase.RarityId
export type AnimId = "spin" | "bounce" | "tumble" | "sway" | "pulse"
export type SizeId = "small" | "medium" | "large" | "giant"

-- MVP: incubator eggs only yaw-spin. Other AnimIds reserved for later.
local ANIM_IDS: { AnimId } = { "spin" }

-- Cumulative weights: Small 50%, Medium 30%, Large 18%, Giant 2%.
local SIZE_ROLLS: { { id: SizeId, cum: number } } = {
    { id = "small", cum = 0.50 },
    { id = "medium", cum = 0.80 },
    { id = "large", cum = 0.98 },
    { id = "giant", cum = 1.00 },
}

local SIZE_LABEL: { [SizeId]: string } = {
    small = "Small",
    medium = "Medium",
    large = "Large",
    giant = "Giant",
}

local SIZE_MULT: { [SizeId]: number } = {
    small = 0.65,
    medium = 1.0,
    large = 1.5,
    -- Exactly 2× Large (model only; same rule as Giant mutation).
    giant = 3.0,
}

local ExhibitLogic = {}

local function clamp01(x: number): number
    return math.clamp(x, 0, 1)
end

function ExhibitLogic.evolveDuration(rarity: string): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return RarityDatabase.ById.common.evolveDurationSec
    end
    return entry.evolveDurationSec
end

function ExhibitLogic.progress(elapsedSec: number, rarity: string): number
    local dur = ExhibitLogic.evolveDuration(rarity)
    if dur <= 0 then
        return 1
    end
    return clamp01(elapsedSec / dur)
end

-- attentionBoost: 0 = none; ~1 = +25% income toward end curve
function ExhibitLogic.incomeAt(rarity: string, progress: number, attention: number): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return 0
    end
    local p = clamp01(progress)
    local mult = 1 + (entry.incomeMultAtEnd - 1) * p
    local attentionFactor = 1 + math.min(attention, 40) * 0.01
    return entry.baseIncomePerSec * mult * attentionFactor
end

-- rng01 in [0,1). Returns integer in [npcMin, npcMax].
function ExhibitLogic.rollNpcCount(rarity: string, rng01: number): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return 1
    end
    local lo = entry.npcMin
    local hi = entry.npcMax
    if hi < lo then
        lo, hi = hi, lo
    end
    local t = math.clamp(rng01, 0, 0.999999)
    return math.floor(lo + t * (hi - lo + 1))
end

-- Avoid roll first: may return 0 visitors (shunned).
function ExhibitLogic.rollCrowd(
    rarity: string,
    avoidRng01: number,
    countRng01: number
): (number, boolean)
    local entry = RarityDatabase.get(rarity)
    if entry and avoidRng01 < entry.npcAvoidChance then
        return 0, true
    end
    return ExhibitLogic.rollNpcCount(rarity, countRng01), false
end

-- Live crowd size from rolled base (ramps in early growth, stays busy after evolve).
-- npcBase 0 → always empty (shunned).
function ExhibitLogic.npcTargetCount(npcBase: number, progress: number, evolved: boolean): number
    local base = math.max(0, math.floor(npcBase + 0.5))
    if base <= 0 then
        return 0
    end
    if evolved or progress >= 1 then
        -- Keep the show busy after grow (was ~45% and looked empty).
        return math.max(2, math.floor(base * 0.9 + 0.5))
    end
    local p = clamp01(progress)
    local ramp = math.clamp(p / 0.2, 0, 1)
    return math.max(0, math.floor(base * ramp + 0.5))
end

function ExhibitLogic.highlightTransparency(progress: number, evolved: boolean): number
    local p = clamp01(progress)
    if evolved or p >= 1 then
        return ExhibitCatalog.HIGHLIGHT_T_END
    end
    local a = ExhibitCatalog.HIGHLIGHT_T_START
    local b = ExhibitCatalog.HIGHLIGHT_T_END
    return a + (b - a) * p
end

function ExhibitLogic.rollSize(rng01: number): SizeId
    local t = math.clamp(rng01, 0, 0.999999)
    for _, entry in SIZE_ROLLS do
        if t < entry.cum then
            return entry.id
        end
    end
    return "giant"
end

function ExhibitLogic.sizeLabel(sizeId: string?): string
    if sizeId == "small" or sizeId == "medium" or sizeId == "large" or sizeId == "giant" then
        return SIZE_LABEL[sizeId]
    end
    return SIZE_LABEL.medium
end

function ExhibitLogic.sizeMult(sizeId: string?): number
    if sizeId == "small" or sizeId == "medium" or sizeId == "large" or sizeId == "giant" then
        return SIZE_MULT[sizeId]
    end
    return SIZE_MULT.medium
end

function ExhibitLogic.hasGiantMutation(mutationIds: { string }?): boolean
    if not mutationIds then
        return false
    end
    for _, id in mutationIds do
        if id == "giant" then
            return true
        end
    end
    return false
end

-- Model scale on stand. Giant size tier and Giant mutation both mean 2× Large
-- (no particle FX for the mutation — scale only).
function ExhibitLogic.visualScale(
    progress: number,
    mutated: boolean,
    sizeId: string?,
    mutationIds: { string }?
): number
    local p = clamp01(progress)
    local growth = 1 + 0.55 * p
    local sizeM = ExhibitLogic.sizeMult(sizeId)
    local giantMut = ExhibitLogic.hasGiantMutation(mutationIds)
    if giantMut then
        sizeM = math.max(sizeM, SIZE_MULT.large * 2)
    end
    local base = sizeM * growth
    if mutated and not giantMut then
        return base * 1.15
    end
    return base
end

-- Incubator hatch: egg shrinks first, then pet grows in its place.
-- progress in [0, HATCH] → egg 1→0; [HATCH, 1] → pet 0→1. Evolved → pet only.
local HATCH_PROGRESS = 0.52

function ExhibitLogic.hatchProgress(): number
    return HATCH_PROGRESS
end

function ExhibitLogic.hatchEggScale(
    progress: number,
    evolved: boolean,
    mutated: boolean,
    sizeId: string?,
    mutationIds: { string }?
): number
    if evolved then
        return 0
    end
    local p = clamp01(progress)
    if p >= HATCH_PROGRESS then
        return 0
    end
    local startScale = ExhibitLogic.visualScale(0, mutated, sizeId, mutationIds)
    return startScale * (1 - p / HATCH_PROGRESS)
end

function ExhibitLogic.hatchPetScale(
    progress: number,
    evolved: boolean,
    mutated: boolean,
    sizeId: string?,
    mutationIds: { string }?
): number
    local full = ExhibitLogic.visualScale(1, mutated, sizeId, mutationIds)
    if evolved then
        return full
    end
    local p = clamp01(progress)
    if p <= HATCH_PROGRESS then
        return 0
    end
    return full * ((p - HATCH_PROGRESS) / (1 - HATCH_PROGRESS))
end

function ExhibitLogic.sellPrice(
    rarity: string,
    progress: number,
    mutated: boolean,
    baseIncome: number,
    mutationStacks: number?
): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return 0
    end
    local p = clamp01(progress)
    local stage = 0.35 + 0.65 * p
    local stacks = math.max(if mutated then 1 else 0, mutationStacks or 0)
    local mutBonus = if stacks > 0 then 1.75 + 0.25 * (stacks - 1) else 1
    return math.floor(baseIncome * entry.sellMult * stage * mutBonus + 0.5)
end

-- Dispenser purchase cost. Size/mutations raise price; name stays template-only.
function ExhibitLogic.buyPrice(rarity: string, sizeId: string?, mutationStacks: number?): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return 0
    end
    local stacks = math.max(0, mutationStacks or 0)
    local mutBonus = if stacks > 0 then 1.25 + 0.15 * (stacks - 1) else 1
    return math.max(
        1,
        math.floor(entry.baseIncomePerSec * ExhibitLogic.sizeMult(sizeId) * 4 * mutBonus + 0.5)
    )
end

function ExhibitLogic.pickAnim(_rng01: number): AnimId
    return "spin"
end

function ExhibitLogic.animIds(): { AnimId }
    return ANIM_IDS
end

function ExhibitLogic.isValidSlot(slotIndex: number): boolean
    return slotIndex == math.floor(slotIndex)
        and slotIndex >= 1
        and slotIndex <= ExhibitCatalog.SLOT_COUNT
end

return ExhibitLogic
