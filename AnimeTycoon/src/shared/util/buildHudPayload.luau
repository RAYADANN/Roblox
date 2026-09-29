--!strict
-- PlayerData → HudPayload. Pure, testable.

local HudPayloadModule
local PlayerDataModule
local ContainerLogic
local MutationLogic
local Constants
if script and script.Parent then
    HudPayloadModule = require(script.Parent.Parent.types.HudPayload)
    PlayerDataModule = require(script.Parent.Parent.types.PlayerData)
    ContainerLogic = require(script.Parent.ContainerLogic)
    MutationLogic = require(script.Parent.MutationLogic)
    Constants = require(script.Parent.Parent.data.Constants)
else
    HudPayloadModule = require("../types/HudPayload")
    PlayerDataModule = require("../types/PlayerData")
    ContainerLogic = require("./ContainerLogic")
    MutationLogic = require("./MutationLogic")
    Constants = require("../data/Constants")
end

type PlayerData = PlayerDataModule.PlayerData
type HudPayload = HudPayloadModule.HudPayload

local buildHudPayload = {}

function buildHudPayload.fromPlayerData(data: PlayerData): HudPayload
    local offers = {}
    for _, offer in data.offers or {} do
        if offer.uid ~= "" then
            table.insert(offers, {
                uid = offer.uid,
                templateId = offer.templateId,
                boxModelName = offer.boxModelName,
                rarity = offer.rarity,
                heroId = offer.heroId,
                displayName = offer.displayName,
                baseIncome = offer.baseIncome,
                buyPrice = ContainerLogic.buyPrice(offer.rarity, #(offer.mutations or {})),
                mutationLabel = MutationLogic.formatLabel(offer.mutations or {}),
            })
        else
            table.insert(offers, {
                uid = "",
                templateId = "",
                boxModelName = "",
                rarity = "common",
                heroId = "",
                displayName = "",
                baseIncome = 0,
                buyPrice = 0,
                mutationLabel = "",
            })
        end
    end

    local slots = {}
    local slotList = data.slots or {}
    for i = 1, Constants.SLOT_COUNT do
        local slot = slotList[i]
        if slot then
            table.insert(slots, {
                uid = slot.uid,
                templateId = slot.templateId,
                boxModelName = slot.boxModelName,
                rarity = slot.rarity,
                heroId = slot.heroId,
                displayName = slot.displayName,
                unpackProgress = slot.unpackProgress,
                unpacked = slot.unpacked,
                mutationLabel = MutationLogic.formatLabel(slot.mutations or {}),
                incomeRate = slot.incomeRate,
                slotIndex = slot.slotIndex or i,
            })
        end
    end

    local inventory = {}
    for _, item in data.inventory or {} do
        table.insert(inventory, {
            uid = item.uid,
            displayName = item.displayName,
            rarity = item.rarity,
            boxModelName = item.boxModelName,
            mutationLabel = MutationLogic.formatLabel(item.mutations or {}),
        })
    end

    return {
        coins = data.coins,
        rebirths = data.rebirths,
        upgrades = table.clone(data.upgrades),
        handUid = data.handUid,
        offers = offers,
        slots = slots,
        inventory = inventory,
    }
end

return buildHudPayload
