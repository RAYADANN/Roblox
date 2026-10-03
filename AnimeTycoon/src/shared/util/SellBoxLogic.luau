--!strict
-- SellBox fill + pickup/sell rules. Pure, CI-tested.

export type ActiveSellBox = {
    coins: number,
    depositCount: number,
}

export type SellCrate = {
    uid: string,
    coins: number,
    depositCount: number,
}

local SellBoxLogic = {}

-- One visual growth step per this many toys.
local TOYS_PER_STEP = 5
-- ~63% fill after this many *steps* (not raw toys).
local FILL_HALF_LIFE = 6
-- Peak Size.X multiplier (half of prior sky-high curve).
local MAX_SIZE_MULT = 14
local TWEEN_SEC = 0.3

function SellBoxLogic.emptyActive(): ActiveSellBox
    return { coins = 0, depositCount = 0 }
end

function SellBoxLogic.toysPerStep(): number
    return TOYS_PER_STEP
end

function SellBoxLogic.growthSteps(depositCount: number): number
    return math.floor(math.max(0, depositCount) / TOYS_PER_STEP)
end

function SellBoxLogic.canPickup(active: ActiveSellBox?): boolean
    return active ~= nil and active.coins > 0
end

function SellBoxLogic.deposit(active: ActiveSellBox, amount: number, toys: number?): ActiveSellBox
    local addToys = if typeof(toys) == "number" then math.max(1, math.floor(toys)) else 1
    local addCoins = math.max(0, amount)
    return {
        coins = active.coins + addCoins,
        depositCount = active.depositCount + addToys,
    }
end

function SellBoxLogic.fill01(depositCount: number): number
    local steps = SellBoxLogic.growthSteps(depositCount)
    return 1 - math.exp(-steps / FILL_HALF_LIFE)
end

--- Grown Size.X for Side / SidePart from authored baseX.
function SellBoxLogic.sizeX(baseX: number, depositCount: number): number
    local fill = SellBoxLogic.fill01(depositCount)
    local mult = 1 + fill * (MAX_SIZE_MULT - 1)
    return math.max(0.05, baseX * mult)
end

--- Alias (older call sites).
function SellBoxLogic.sizeY(baseY: number, depositCount: number): number
    return SellBoxLogic.sizeX(baseY, depositCount)
end

function SellBoxLogic.tweenSeconds(): number
    return TWEEN_SEC
end

function SellBoxLogic.maxSizeMult(): number
    return MAX_SIZE_MULT
end

function SellBoxLogic.totalCrateCoins(crates: { SellCrate }): number
    local sum = 0
    for _, crate in crates do
        sum += math.max(0, crate.coins)
    end
    return sum
end

return SellBoxLogic
