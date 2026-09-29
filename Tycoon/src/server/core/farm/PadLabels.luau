--!strict
-- Pad billboard text / tones from live PlayerData.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local FarmLogic = require(ReplicatedStorage.shared.util.FarmLogic)
local FinishNowLogic = require(ReplicatedStorage.shared.util.FinishNowLogic)
local FormatMoney = require(ReplicatedStorage.shared.util.FormatMoney)
local GamepassLogic = require(ReplicatedStorage.shared.util.GamepassLogic)
local PadLogic = require(ReplicatedStorage.shared.util.PadLogic)
local PadVisuals = require(script.Parent.Parent.PadVisuals)
local WorldFarmFactory = require(script.Parent.Parent.WorldFarmFactory)

local Types = require(script.Parent.Types)

type FarmHost = Types.FarmHost
type PlayerData = Types.PlayerData
type Session = Types.Session

local PadLabels = {}

local function money(n: number): string
    return `$` .. FormatMoney.short(n)
end

function PadLabels._refreshLabels(self: FarmHost, player: Player)
    local session = self._sessions[player]
    local data = self:_data(player)
    if session == nil or data == nil then
        return
    end
    local pads = session.pads
    local buyTier = FarmLogic.buyTier(data.productionLevel)
    local buy = function(qty: number): string
        return money(FarmLogic.batchCost(data.buyCount, qty))
    end
    WorldFarmFactory.setPadText(pads.Buy1, `Buy 1 Tier {buyTier}`, buy(1))
    WorldFarmFactory.setPadText(pads.Buy5, `Buy 5 Tier {buyTier}`, buy(5))
    WorldFarmFactory.setPadText(pads.Buy25, `Buy 25 Tier {buyTier}`, buy(25))
    WorldFarmFactory.setPadText(pads.Buy100, `Buy 100 Tier {buyTier}`, buy(100))
    WorldFarmFactory.setPadText(pads.Merge, "MERGE", "3 same")
    WorldFarmFactory.setPadText(
        pads.Deposit,
        "Sell Items",
        FormatMoney.short(data.backpackEggs) .. " items"
    )
    local processDeltaCash =
        FarmLogic.cashFromEggs(FarmLogic.processUpgradeDelta(data.processLevel), data.rebirths)
    WorldFarmFactory.setPadText(pads.CollectCash, "Collect Cash", money(data.pendingCash))
    WorldFarmFactory.setPadText(
        pads.UpgradeProcess,
        `+$` .. FormatMoney.rate(processDeltaCash) .. ` per second`,
        money(FarmLogic.processUpgradeCost(data.processLevel))
    )
    local productionNeed = FarmLogic.productionSummonNeed(data.productionLevel)
    local nextBuyTier = FarmLogic.buyTier(data.productionLevel) + 1
    local summonHave = math.min(data.buyCount, productionNeed)
    local summonFrac = FarmLogic.productionUpgradeProgress(data.buyCount, data.productionLevel)
    if data.productionLevel >= data.rebirths then
        WorldFarmFactory.setPadText(pads.UpgradeProduction, "Upgrade Locked", "")
        PadVisuals.setPadSummonProgress(pads.UpgradeProduction, 1, "Need rebirth", true)
    elseif data.buyCount < productionNeed then
        WorldFarmFactory.setPadText(pads.UpgradeProduction, `Unlock Tier {nextBuyTier}`, "")
        PadVisuals.setPadSummonProgress(
            pads.UpgradeProduction,
            summonFrac,
            `{FormatMoney.comma(summonHave)}/{FormatMoney.comma(productionNeed)}`,
            true
        )
    else
        WorldFarmFactory.setPadText(pads.UpgradeProduction, `Unlock Tier {nextBuyTier}`, "")
        PadVisuals.setPadSummonProgress(
            pads.UpgradeProduction,
            1,
            money(FarmLogic.productionUpgradeCost(data.productionLevel)),
            true
        )
    end
    WorldFarmFactory.setPadText(pads.AutoCollectEggs, "Auto Collect Items", nil)
    local eggsPass = GamepassLogic.passForField("autoCollectEggs")
    if eggsPass then
        PadVisuals.setPadRobuxPrice(pads.AutoCollectEggs, eggsPass.robux, data.autoCollectEggs)
    end
    WorldFarmFactory.setPadText(pads.AutoCollectCash, "Auto Collect Cash", nil)
    local cashPass = GamepassLogic.passForField("autoCollectCash")
    if cashPass then
        PadVisuals.setPadRobuxPrice(pads.AutoCollectCash, cashPass.robux, data.autoCollectCash)
    end
    WorldFarmFactory.setPadText(pads.FinishNow, "Finish Now", nil)
    PadVisuals.setPadRobuxPrice(pads.FinishNow, FinishNowLogic.ROBUX, false)
    WorldFarmFactory.setPadText(pads.DoubleItems, "X2 Items", nil)
    local x2Pass = GamepassLogic.passForField("doubleItems")
    if x2Pass then
        PadVisuals.setPadRobuxPrice(pads.DoubleItems, x2Pass.robux, data.doubleItems)
    end
    WorldFarmFactory.setPadText(pads.GroupReward, "Group Reward", money(Constants.GROUP_REWARD))
    WorldFarmFactory.setCountBoard(
        session.plot.island,
        FarmLogic.cashFromEggs(data.shopQueue, data.rebirths),
        FarmLogic.cashFromEggs(FarmLogic.processPerSec(data.processLevel), data.rebirths)
    )

    local function buyTone(qty: number)
        return if PadLogic.buyCanPay(data.coins, data.buyCount, qty) then "green" else "red"
    end
    PadVisuals.setBuyTone(pads.Buy1, buyTone(1))
    PadVisuals.setBuyTone(pads.Buy5, buyTone(5))
    PadVisuals.setBuyTone(pads.Buy25, buyTone(25))
    PadVisuals.setBuyTone(pads.Buy100, buyTone(100))

    PadVisuals.setUpgradeTone(pads.CollectCash, "green")

    PadVisuals.setMergeTone(
        pads.Merge,
        if PadLogic.mergeReady(data.units) then "orange" else "gray"
    )

    PadVisuals.setUpgradeTone(pads.UpgradeProcess, "green")
    PadVisuals.setUpgradeTone(
        pads.UpgradeProduction,
        if PadLogic.productionUpgradeReady(
                data.productionLevel,
                data.rebirths,
                data.buyCount,
                data.coins
            )
            then "green"
            else "gray"
    )
end

return PadLabels
