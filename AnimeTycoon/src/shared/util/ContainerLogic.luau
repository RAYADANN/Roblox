--!strict
-- Pure: unpack, buy price, income, produce timing.

local RarityDatabase
local MutationDatabase
local ContainerCatalog
local HeroCatalog
local BoxVisualLogic
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
    MutationDatabase = require(script.Parent.Parent.data.MutationDatabase)
    ContainerCatalog = require(script.Parent.Parent.data.ContainerCatalog)
    HeroCatalog = require(script.Parent.Parent.data.HeroCatalog)
    BoxVisualLogic = require(script.Parent.BoxVisualLogic)
else
    RarityDatabase = require("../data/RarityDatabase")
    MutationDatabase = require("../data/MutationDatabase")
    ContainerCatalog = require("../data/ContainerCatalog")
    HeroCatalog = require("../data/HeroCatalog")
    BoxVisualLogic = require("./BoxVisualLogic")
end

local ContainerLogic = {}

local function clamp01(x: number): number
    return math.clamp(x, 0, 1)
end

function ContainerLogic.mutationIncomeMult(mutationIds: { string }?): number
    if not mutationIds or #mutationIds == 0 then
        return 1
    end
    local mult = 1
    for _, id in mutationIds do
        local def = MutationDatabase.get(id)
        if def then
            mult *= def.incomeMult
        end
    end
    return mult
end

function ContainerLogic.unpackDuration(
    rarity: string,
    timeMult: number?,
    fastUnpack: boolean?
): number
    if fastUnpack == true then
        return 3
    end
    local entry = RarityDatabase.get(rarity)
    local base = if entry
        then entry.unpackDurationSec
        else RarityDatabase.ById.common.unpackDurationSec
    local mult = if typeof(timeMult) == "number" then math.clamp(timeMult, 0.5, 1) else 1
    return base * mult
end

function ContainerLogic.unpackProgress(
    elapsedSec: number,
    rarity: string,
    timeMult: number?,
    fastUnpack: boolean?
): number
    local dur = ContainerLogic.unpackDuration(rarity, timeMult, fastUnpack)
    if dur <= 0 then
        return 1
    end
    return clamp01(elapsedSec / dur)
end

--- Seconds left until unpack completes (0 when ready).
function ContainerLogic.unpackRemainingSec(
    elapsedSec: number,
    rarity: string,
    timeMult: number?,
    fastUnpack: boolean?
): number
    local dur = ContainerLogic.unpackDuration(rarity, timeMult, fastUnpack)
    return math.max(0, dur - math.max(0, elapsedSec))
end

--- Unix end time for client countdown (placedAt + duration).
function ContainerLogic.unpackEndsAt(
    placedAt: number,
    rarity: string,
    timeMult: number?,
    fastUnpack: boolean?
): number
    return placedAt + ContainerLogic.unpackDuration(rarity, timeMult, fastUnpack)
end

--- Billboard timer: "12s" or "1:05".
function ContainerLogic.formatRemaining(sec: number): string
    local s = math.max(0, math.ceil(sec - 1e-9))
    if s >= 60 then
        local m = math.floor(s / 60)
        local r = s % 60
        return string.format("%d:%02d", m, r)
    end
    return `{s}s`
end

function ContainerLogic.incomePerMini(rarity: string, mutationIds: { string }?): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return 0
    end
    return math.max(
        1,
        math.floor(entry.baseIncomePerMini * ContainerLogic.mutationIncomeMult(mutationIds) + 0.5)
    )
end

function ContainerLogic.produceInterval(rarity: string): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return 4
    end
    return entry.produceIntervalSec
end

--- Expected coins/sec for one producing hero slot.
function ContainerLogic.incomePerSecond(rarity: string, mutationIds: { string }?): number
    local interval = ContainerLogic.produceInterval(rarity)
    if interval <= 0 then
        return 0
    end
    return ContainerLogic.incomePerMini(rarity, mutationIds) / interval
end

--- Sum $/s from HUD/world slots that are already unpacked (producing).
function ContainerLogic.totalIncomePerSecond(slots: {
    {
        unpacked: boolean?,
        rarity: string?,
        incomeRate: number?,
    }
}): number
    local sum = 0
    for _, slot in slots do
        if slot.unpacked == true then
            local rate = slot.incomeRate
            local rarity = slot.rarity or "common"
            if typeof(rate) == "number" and rate > 0 then
                local interval = ContainerLogic.produceInterval(rarity)
                if interval > 0 then
                    sum += rate / interval
                end
            else
                sum += ContainerLogic.incomePerSecond(rarity, nil)
            end
        end
    end
    return sum
end

function ContainerLogic.buyPrice(rarity: string, mutationStacks: number?): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return 10
    end
    local stacks = math.max(0, mutationStacks or 0)
    local mutBonus = if stacks > 0 then 1.2 + 0.15 * (stacks - 1) else 1
    return math.max(1, math.floor(12 * entry.buyMult * mutBonus + 0.5))
end

function ContainerLogic.pickTemplateId(rng01: number): string
    local all = ContainerCatalog.all()
    local total = 0
    for _, t in all do
        total += t.weight
    end
    if total <= 0 then
        return "box1"
    end
    local roll = math.clamp(rng01, 0, 0.999999) * total
    local acc = 0
    for _, t in all do
        acc += t.weight
        if roll < acc then
            return t.id
        end
    end
    return all[#all].id
end

--- Hero from rarity pool only (Workspace.Герои / HeroCatalog).
function ContainerLogic.pickHeroId(rarity: string, rng01: number): string
    local pool = HeroCatalog.pool(rarity)
    if #pool == 0 then
        return HeroCatalog.fallbackHeroId()
    end
    local idx = math.floor(math.clamp(rng01, 0, 0.999999) * #pool) + 1
    return pool[idx]
end

--- Box mesh from stand level + random palette (not rarity).
function ContainerLogic.pickBoxModelName(standLevel: number, rng01: number): string
    return BoxVisualLogic.pickBoxModelName(standLevel, rng01)
end

return ContainerLogic
