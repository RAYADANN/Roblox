--!strict
-- Pure: Limited Robux offer → container instance + mutation label aliases.

local ContainerModule
local HeroCatalog
local LimitedOfferDatabase
local MutationLogic
if script and script.Parent then
    ContainerModule = require(script.Parent.Parent.types.Container)
    HeroCatalog = require(script.Parent.Parent.data.HeroCatalog)
    LimitedOfferDatabase = require(script.Parent.Parent.data.LimitedOfferDatabase)
    MutationLogic = require(script.Parent.MutationLogic)
else
    ContainerModule = require("../types/Container")
    HeroCatalog = require("../data/HeroCatalog")
    LimitedOfferDatabase = require("../data/LimitedOfferDatabase")
    MutationLogic = require("./MutationLogic")
end

type ContainerInstance = ContainerModule.ContainerInstance
type LimitedOffer = LimitedOfferDatabase.LimitedOffer

local MUTATION_ALIASES: { [string]: string } = {
    prysmatic = "prismatic",
    prism = "prismatic",
    gold = "golden",
}

local LimitedLogic = {}

function LimitedLogic.templateIdForStand(standId: string): string
    return "limited_" .. standId
end

function LimitedLogic.standIdFromTemplateId(templateId: string?): string?
    if typeof(templateId) ~= "string" or templateId == "" then
        return nil
    end
    return string.match(templateId, "^limited_(.+)$")
end

function LimitedLogic.offerFromTemplateId(templateId: string?): LimitedOffer?
    local standId = LimitedLogic.standIdFromTemplateId(templateId)
    if not standId then
        return nil
    end
    return LimitedOfferDatabase.get(standId)
end

function LimitedLogic.normalizeMutationId(raw: string): string?
    if typeof(raw) ~= "string" or raw == "" then
        return nil
    end
    local lower = string.lower(raw)
    local aliased = MUTATION_ALIASES[lower] or lower
    local MutationDatabase
    if script and script.Parent then
        MutationDatabase = require(script.Parent.Parent.data.MutationDatabase)
    else
        MutationDatabase = require("../data/MutationDatabase")
    end
    if MutationDatabase.get(aliased) then
        return aliased
    end
    return nil
end

--- Keep saved limited items aligned with stand authoring (hero / Null / VFX income).
function LimitedLogic.syncContainerFromOffer(item: ContainerInstance, offer: LimitedOffer)
    item.templateId = LimitedLogic.templateIdForStand(offer.standId)
    item.heroId = offer.heroId
    item.displayName = HeroCatalog.displayName(offer.heroId)
    item.rarity = offer.rarity :: any
    item.mutations = MutationLogic.normalizeStack(offer.mutations)
    item.baseIncome = offer.incomePerMini
    item.incomeRate = offer.incomePerMini
end

function LimitedLogic.buildContainer(offer: LimitedOffer, uid: string): ContainerInstance
    local mutations = MutationLogic.normalizeStack(offer.mutations)
    return {
        uid = uid,
        templateId = LimitedLogic.templateIdForStand(offer.standId),
        boxModelName = "Box3",
        rarity = offer.rarity :: any,
        heroId = offer.heroId,
        displayName = HeroCatalog.displayName(offer.heroId),
        baseIncome = offer.incomePerMini,
        mutations = mutations,
        placedAt = nil,
        slotIndex = nil,
        unpackProgress = 1,
        unpacked = true,
        incomeRate = offer.incomePerMini,
    }
end

return LimitedLogic
