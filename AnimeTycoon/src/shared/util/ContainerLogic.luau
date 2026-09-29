--!strict
-- Pure: unpack, buy price, income, produce timing.

local RarityDatabase
local MutationDatabase
local ContainerCatalog
if script and script.Parent then
    RarityDatabase = require(script.Parent.Parent.data.RarityDatabase)
    MutationDatabase = require(script.Parent.Parent.data.MutationDatabase)
    ContainerCatalog = require(script.Parent.Parent.data.ContainerCatalog)
else
    RarityDatabase = require("../data/RarityDatabase")
    MutationDatabase = require("../data/MutationDatabase")
    ContainerCatalog = require("../data/ContainerCatalog")
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

function ContainerLogic.unpackDuration(rarity: string): number
    local entry = RarityDatabase.get(rarity)
    if not entry then
        return RarityDatabase.ById.common.unpackDurationSec
    end
    return entry.unpackDurationSec
end

function ContainerLogic.unpackProgress(elapsedSec: number, rarity: string): number
    local dur = ContainerLogic.unpackDuration(rarity)
    if dur <= 0 then
        return 1
    end
    return clamp01(elapsedSec / dur)
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

function ContainerLogic.pickHeroId(templateId: string, rng01: number): string
    local template = ContainerCatalog.get(templateId)
    if not template or #template.heroPool == 0 then
        return "Tanjiro"
    end
    local idx = math.floor(math.clamp(rng01, 0, 0.999999) * #template.heroPool) + 1
    return template.heroPool[idx]
end

return ContainerLogic
