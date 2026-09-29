--!strict
-- Pure logic: cash-gated rebirth (have money → reset farm → keep cash mult). CI-tested (Lune).

local Constants
local PlayerDataModule
local RebirthDatabase
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
    PlayerDataModule = require(script.Parent.Parent.types.PlayerData)
    RebirthDatabase = require(script.Parent.Parent.data.RebirthDatabase)
else
    Constants = require("../data/Constants")
    PlayerDataModule = require("../types/PlayerData")
    RebirthDatabase = require("../data/RebirthDatabase")
end

type PlayerData = PlayerDataModule.PlayerData
type Tier = RebirthDatabase.Tier

local RebirthLogic = {}

local function nextTier(rebirths: number): Tier
    local index = math.max(math.floor(rebirths), 0) + 1
    local tiers = RebirthDatabase.Tiers
    if index <= #tiers then
        return tiers[index]
    end
    local last = tiers[#tiers]
    local extra = index - #tiers
    local cash = last.cashRequired
    local mult = last.cashMultiplier
    for _ = 1, extra do
        cash *= RebirthDatabase.OVERFLOW_COST_MULT
        mult *= RebirthDatabase.OVERFLOW_CASH_MULT
    end
    return {
        cashRequired = math.floor(cash),
        cashMultiplier = mult,
    }
end

function RebirthLogic.cost(rebirths: number): number
    return nextTier(rebirths).cashRequired
end

function RebirthLogic.valueMultiplier(rebirths: number): number
    local n = math.max(math.floor(rebirths), 0)
    if n <= 0 then
        return 1
    end
    local tiers = RebirthDatabase.Tiers
    if n <= #tiers then
        return tiers[n].cashMultiplier
    end
    local mult = tiers[#tiers].cashMultiplier
    for _ = #tiers + 1, n do
        mult *= RebirthDatabase.OVERFLOW_CASH_MULT
    end
    return mult
end

function RebirthLogic.canAfford(coins: number, rebirths: number): boolean
    return coins >= RebirthLogic.cost(rebirths)
end

--- Progress toward next rebirth: (current, required). Current is capped at required.
function RebirthLogic.progress(coins: number, rebirths: number): (number, number)
    local need = RebirthLogic.cost(rebirths)
    return math.min(math.max(coins, 0), need), need
end

function RebirthLogic.progressFraction(coins: number, rebirths: number): number
    local have, need = RebirthLogic.progress(coins, rebirths)
    if need <= 0 then
        return 1
    end
    return have / need
end

--- Absolute income multiplier after the next rebirth (e.g. 2 → "X2 Coins").
function RebirthLogic.rewardLabel(rebirths: number): string
    local mult = RebirthLogic.valueMultiplier(rebirths + 1)
    local text = if mult == math.floor(mult)
        then tostring(math.floor(mult))
        else string.format("%.1f", mult)
    return `X{text} Coins`
end

--- Mutates profile in place after caller validated canAfford. Keeps paid unlocks.
function RebirthLogic.apply(data: PlayerData)
    data.rebirths += 1
    data.coins = Constants.START_COINS
    data.pendingCash = 0
    data.backpackEggs = 0
    data.luckyBlocks = 0
    data.shopQueue = 0
    data.processLevel = 0
    data.productionLevel = 0
    data.units = {}
    data.buyCount = 0
    data.upgrades = {}
end

return RebirthLogic
