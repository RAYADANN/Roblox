--!strict
-- PlayerData → HudPayload. Pure, CI-tested.

local ExhibitLogic
local MutationLogic
local PlayerDataModule
local HudPayloadModule
local Constants
if script and script.Parent then
    ExhibitLogic = require(script.Parent.ExhibitLogic)
    MutationLogic = require(script.Parent.MutationLogic)
    PlayerDataModule = require(script.Parent.Parent.types.PlayerData)
    HudPayloadModule = require(script.Parent.Parent.types.HudPayload)
    Constants = require(script.Parent.Parent.data.Constants)
else
    ExhibitLogic = require("./ExhibitLogic")
    MutationLogic = require("./MutationLogic")
    PlayerDataModule = require("../types/PlayerData")
    HudPayloadModule = require("../types/HudPayload")
    Constants = require("../data/Constants")
end

type PlayerData = PlayerDataModule.PlayerData
type HudPayload = HudPayloadModule.HudPayload
type SlotHud = HudPayloadModule.SlotHud
type OfferHud = HudPayloadModule.OfferHud
type InvHud = HudPayloadModule.InvHud

local buildHudPayload = {}

local function handNameFrom(data: PlayerData): string?
    if not data.handUid then
        return nil
    end
    for _, item in data.inventory do
        if item.uid == data.handUid then
            return item.displayName
        end
    end
    return nil
end

function buildHudPayload.fromPlayerData(data: PlayerData, nowSec: number?): HudPayload
    local now = nowSec or 0
    local offerCount = Constants.OFFER_COUNT
    local offers: { OfferHud } = table.create(offerCount)
    for i = 1, offerCount do
        local o = data.offers[i]
        if o and o.uid ~= "" then
            local mutations = o.mutations or {}
            offers[i] = {
                uid = o.uid,
                templateId = o.templateId,
                rarity = o.rarity,
                displayName = o.displayName,
                sizeId = o.sizeId or "medium",
                baseIncome = o.baseIncome,
                buyPrice = ExhibitLogic.buyPrice(o.rarity, o.sizeId, #mutations),
                mutationLabel = MutationLogic.formatLabel(mutations),
            }
        else
            -- Dense JSON slot: empty pad until next Spin (uid "").
            offers[i] = {
                uid = "",
                templateId = "",
                rarity = "",
                displayName = "",
                sizeId = "medium",
                baseIncome = 0,
                buyPrice = 0,
                mutationLabel = "",
            }
        end
    end

    local inventory: { InvHud } = {}
    for _, item in data.inventory do
        table.insert(inventory, {
            uid = item.uid,
            rarity = item.rarity,
            displayName = item.displayName,
            baseIncome = item.baseIncome,
        })
    end

    local slots: { SlotHud } = {}
    for i = 1, Constants.SLOT_COUNT do
        local ex = data.slots[i]
        if ex == nil then
            table.insert(slots, {
                occupied = false,
                uid = nil,
                rarity = nil,
                displayName = nil,
                progress = 0,
                incomeRate = 0,
                evolved = false,
                mutated = false,
                mutationLabel = "",
                sellPrice = 0,
            })
        else
            local progress = ex.evolveProgress
            if ex.placedAt and not ex.evolved then
                progress = ExhibitLogic.progress(now - ex.placedAt, ex.rarity)
            end
            local incomeRate = ExhibitLogic.incomeAt(ex.rarity, progress, ex.attention)
            local mutations = ex.mutations or {}
            local stacks = #mutations
            if stacks == 0 and ex.mutationStacks then
                stacks = ex.mutationStacks
            end
            table.insert(slots, {
                occupied = true,
                uid = ex.uid,
                rarity = ex.rarity,
                displayName = ex.displayName,
                progress = progress,
                incomeRate = incomeRate,
                evolved = ex.evolved,
                mutated = ex.mutated or stacks > 0,
                mutationLabel = MutationLogic.formatLabel(mutations),
                sellPrice = ExhibitLogic.sellPrice(
                    ex.rarity,
                    progress,
                    ex.mutated or stacks > 0,
                    ex.baseIncome,
                    stacks
                ),
            })
        end
    end

    return {
        coins = data.coins,
        plotId = data.plotId or 0,
        favoriteBank = if typeof(data.favoriteBank) == "number" then data.favoriteBank else 0,
        offers = offers,
        slots = slots,
        inventory = inventory,
        handUid = data.handUid,
        handName = handNameFrom(data),
    }
end

return buildHudPayload
