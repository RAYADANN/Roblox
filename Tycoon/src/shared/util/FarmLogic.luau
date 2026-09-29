--!strict
-- Pure farm formulas. No Roblox services.

local Constants
local DropDatabase
local RebirthLogic
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
    DropDatabase = require(script.Parent.Parent.data.DropDatabase)
    RebirthLogic = require(script.Parent.RebirthLogic)
else
    Constants = require("../data/Constants")
    DropDatabase = require("../data/DropDatabase")
    RebirthLogic = require("./RebirthLogic")
end

export type DropKind = DropDatabase.DropKind

local FarmLogic = {}

function FarmLogic.emptySlots(unitCount: number, maxSlots: number): number
    return math.max(0, maxSlots - unitCount)
end

function FarmLogic.unitCost(buyCount: number): number
    return math.max(1, math.floor(Constants.UNIT_BASE_COST * Constants.UNIT_COST_MULT ^ buyCount))
end

function FarmLogic.batchCost(buyCount: number, qty: number): number
    if qty <= 0 then
        return 0
    end
    -- Pack pads are flat multiples of the current single-buy price (5× / 25× / 100×).
    return FarmLogic.unitCost(buyCount) * qty
end

-- True if qty fits in empty slots, or applyBuy + autoMergeIfFull ends ≤ maxSlots.
-- Lets Buy 25/100 work on a 40-slot plot when triples can absorb the overflow.
function FarmLogic.wouldFitAfterBuy(
    units: { number },
    qty: number,
    maxSlots: number,
    productionLevel: number?
): boolean
    if qty <= 0 then
        return false
    end
    if FarmLogic.emptySlots(#units, maxSlots) >= qty then
        return true
    end
    local nextUnits = FarmLogic.applyBuy(units, qty, productionLevel)
    if #nextUnits <= maxSlots then
        return true
    end
    local merged = FarmLogic.autoMergeIfFull(nextUnits, maxSlots)
    return merged ~= nil and #merged <= maxSlots
end

function FarmLogic.canBuy(
    units: { number },
    qty: number,
    coins: number,
    buyCount: number,
    maxSlots: number,
    productionLevel: number?
): (boolean, string?)
    if qty <= 0 then
        return false, "invalid_qty"
    end
    if not FarmLogic.wouldFitAfterBuy(units, qty, maxSlots, productionLevel) then
        return false, "no_slots"
    end
    local cost = FarmLogic.batchCost(buyCount, qty)
    if coins < cost then
        return false, "no_coins"
    end
    return true, nil
end

--- Tier of dummies spawned by Buy pads (1 at productionLevel 0).
function FarmLogic.buyTier(productionLevel: number): number
    return Constants.BUY_TIER + math.max(0, math.floor(productionLevel))
end

function FarmLogic.applyBuy(units: { number }, qty: number, productionLevel: number?): { number }
    local tier = FarmLogic.buyTier(productionLevel or 0)
    local nextUnits = table.clone(units)
    for _ = 1, qty do
        table.insert(nextUnits, tier)
    end
    return FarmLogic.sortUnitsDesc(nextUnits)
end

--- Heroes that must be summoned (buyCount) before the next production upgrade.
function FarmLogic.productionSummonNeed(productionLevel: number): number
    local level = math.max(0, math.floor(productionLevel))
    return Constants.PRODUCTION_SUMMON_BASE + Constants.PRODUCTION_SUMMON_STEP * level
end

--- Max productionLevel equals rebirths (1 rebirth → 1 upgrade).
function FarmLogic.canUpgradeProduction(
    productionLevel: number,
    rebirths: number,
    buyCount: number,
    coins: number
): (boolean, string?)
    local level = math.max(0, math.floor(productionLevel))
    if level >= math.max(0, math.floor(rebirths)) then
        return false, "need_rebirth"
    end
    local need = FarmLogic.productionSummonNeed(level)
    if buyCount < need then
        return false, "need_summons"
    end
    local cost = FarmLogic.productionUpgradeCost(level)
    if coins < cost then
        return false, "no_coins"
    end
    return true, nil
end

function FarmLogic.productionUpgradeProgress(buyCount: number, productionLevel: number): number
    local need = FarmLogic.productionSummonNeed(productionLevel)
    if need <= 0 then
        return 1
    end
    return math.clamp(buyCount / need, 0, 1)
end

function FarmLogic.sortUnitsDesc(units: { number }): { number }
    local sorted = table.clone(units)
    table.sort(sorted, function(a: number, b: number)
        return a > b
    end)
    return sorted
end

function FarmLogic.mergeTier(units: { number }): number?
    local counts: { [number]: number } = {}
    for _, tier in units do
        counts[tier] = (counts[tier] or 0) + 1
    end
    local best: number? = nil
    for tier, count in counts do
        if count >= Constants.MERGE_COUNT then
            if best == nil or tier < best then
                best = tier
            end
        end
    end
    return best
end

function FarmLogic.applyMerge(units: { number }, tier: number): { number }?
    local removed = 0
    local nextUnits: { number } = {}
    for _, t in units do
        if t == tier and removed < Constants.MERGE_COUNT then
            removed += 1
        else
            table.insert(nextUnits, t)
        end
    end
    if removed < Constants.MERGE_COUNT then
        return nil
    end
    table.insert(nextUnits, tier + 1)
    return FarmLogic.sortUnitsDesc(nextUnits)
end

-- Merge every available group in one pass, cascading (9×1 → 3×2 → 1×3).
function FarmLogic.mergeAll(units: { number }): { number }?
    local counts: { [number]: number } = {}
    for _, tier in units do
        counts[tier] = (counts[tier] or 0) + 1
    end

    local changed = false
    while true do
        local tier: number? = nil
        for t, count in counts do
            if count >= Constants.MERGE_COUNT then
                if tier == nil or t < tier then
                    tier = t
                end
            end
        end
        if tier == nil then
            break
        end

        local groups = math.floor(counts[tier] / Constants.MERGE_COUNT)
        counts[tier] -= groups * Constants.MERGE_COUNT
        if counts[tier] <= 0 then
            counts[tier] = nil
        end
        counts[tier + 1] = (counts[tier + 1] or 0) + groups
        changed = true
    end

    if not changed then
        return nil
    end

    local nextUnits: { number } = {}
    for tier, count in counts do
        for _ = 1, count do
            table.insert(nextUnits, tier)
        end
    end
    return FarmLogic.sortUnitsDesc(nextUnits)
end

-- When slots are full and a merge is possible, run mergeAll (same as Merge pad).
-- Loops while still full && mergeable; each pass must reduce unit count.
-- Returns nil if not full or no mergeable triple.
function FarmLogic.autoMergeIfFull(units: { number }, maxSlots: number): { number }?
    local current = units
    local result: { number }? = nil
    while #current >= maxSlots do
        local merged = FarmLogic.mergeAll(current)
        if merged == nil then
            break
        end
        if #merged >= #current then
            break
        end
        current = merged
        result = current
    end
    return result
end

function FarmLogic.layIntervalSec(tier: number, productionLevel: number): number
    local faster = 1 + math.max(0, tier - 1) * 0.18 + productionLevel * 0.12
    return math.max(Constants.LAY_MIN_SEC, Constants.LAY_BASE_SEC / faster)
end

function FarmLogic.rollDropKind(tier: number, rand: number): DropKind
    local r = math.clamp(rand, 0, 0.999999)
    if r < 0.02 then
        return "lucky"
    end
    if tier >= 8 and r < 0.08 then
        return "diamond"
    end
    if tier >= 5 and r < 0.16 then
        return "shiny"
    end
    if tier >= 3 and r < 0.28 then
        return "gold"
    end
    return "normal"
end

function FarmLogic.tierBaseValue(tier: number): number
    local t = math.max(1, math.floor(tier))
    return math.floor(Constants.DROP_TIER_BASE * Constants.DROP_TIER_MULT ^ (t - 1) + 0.5)
end

function FarmLogic.dropValue(kind: DropKind, doubleItems: boolean, tier: number?): number
    if kind == "lucky" then
        return 0
    end
    local value = DropDatabase[kind].value * FarmLogic.tierBaseValue(tier or 1)
    if doubleItems then
        value *= 2
    end
    return value
end

--- Next upgrade gain from a known rate (flat floor early, then +10%).
function FarmLogic.processUpgradeDeltaFromRate(rate: number): number
    return math.max(Constants.PROCESS_UPGRADE_MIN_DELTA, rate * Constants.PROCESS_UPGRADE_FRAC)
end

function FarmLogic.processPerSec(processLevel: number): number
    local level = math.max(math.floor(processLevel), 0)
    local rate = Constants.PROCESS_BASE_PER_SEC
    for _ = 1, level do
        rate += FarmLogic.processUpgradeDeltaFromRate(rate)
    end
    return rate
end

function FarmLogic.processUpgradeDelta(processLevel: number): number
    return FarmLogic.processUpgradeDeltaFromRate(FarmLogic.processPerSec(processLevel))
end

function FarmLogic.processUpgradeCost(processLevel: number): number
    return math.floor(
        Constants.PROCESS_UPGRADE_BASE * Constants.PROCESS_UPGRADE_MULT ^ processLevel
    )
end

function FarmLogic.productionUpgradeCost(productionLevel: number): number
    return math.floor(
        Constants.PRODUCTION_UPGRADE_BASE * Constants.PRODUCTION_UPGRADE_MULT ^ productionLevel
    )
end

function FarmLogic.depositAmount(backpackEggs: number, multiplier: number): number
    if backpackEggs <= 0 then
        return 0
    end
    return backpackEggs * multiplier
end

function FarmLogic.processTick(shopQueue: number, perSec: number, dt: number): (number, number)
    if shopQueue <= 0 or perSec <= 0 or dt <= 0 then
        return 0, shopQueue
    end
    local converted = math.min(shopQueue, perSec * dt)
    return converted, shopQueue - converted
end

function FarmLogic.cashFromEggs(eggValue: number, rebirths: number): number
    return eggValue * Constants.CASH_PER_EGG * RebirthLogic.valueMultiplier(rebirths)
end

function FarmLogic.offlineEggs(
    units: { number },
    elapsedSec: number,
    productionLevel: number,
    doubleItems: boolean
): number
    local dt = math.clamp(elapsedSec, 0, Constants.OFFLINE_CAP_SEC)
    if dt <= 0 or #units == 0 then
        return 0
    end
    local total = 0
    for _, tier in units do
        local interval = FarmLogic.layIntervalSec(tier, productionLevel)
        local lays = math.floor(dt / interval)
        -- Offline uses normal-drop value for that dummy tier; no lucky rolls while away.
        local value = FarmLogic.dropValue("normal", doubleItems, tier)
        total += lays * value
    end
    return total
end

function FarmLogic.multiplierFromIndex(index: number): number
    local steps = math.floor(
        (Constants.MULTIPLIER_MAX - Constants.MULTIPLIER_MIN) / Constants.MULTIPLIER_STEP + 0.5
    )
    local i = index % (steps + 1)
    return math.floor((Constants.MULTIPLIER_MIN + i * Constants.MULTIPLIER_STEP) * 10 + 0.5) / 10
end

function FarmLogic.clampMultiplier(value: number): number
    return math.clamp(value, Constants.MULTIPLIER_MIN, Constants.MULTIPLIER_MAX)
end

function FarmLogic.tierColor(tier: number): Color3
    local h = ((tier - 1) * 0.13) % 1
    return Color3.fromHSV(h, 0.62, 0.95)
end

export type Vec3 = { x: number, y: number, z: number }

-- Local offset from Dummy slot into the Stand trough (negative Look / local -Z).
function FarmLogic.dropSpawnLocalOffset(randX: number, randInto: number): Vec3
    local x = (math.clamp(randX, 0, 1) - 0.5) * 2 * Constants.DROP_SPAWN_JITTER_X
    local z = Constants.DROP_SPAWN_INTO_Z
        - math.clamp(randInto, 0, 1) * Constants.DROP_SPAWN_INTO_SPREAD
    return {
        x = x,
        y = Constants.DROP_SPAWN_Y,
        z = z,
    }
end

-- Flat conveyor push used by Stand floor parts (Chicken Farm style).
function FarmLogic.conveyorVelocity(lookX: number, lookZ: number, speed: number): Vec3
    local mag = math.sqrt(lookX * lookX + lookZ * lookZ)
    if mag < 1e-4 then
        return { x = 0, y = 0, z = 0 }
    end
    return {
        x = (lookX / mag) * speed,
        y = 0,
        z = (lookZ / mag) * speed,
    }
end

-- True when a ground drop has reached the Stand tip collect zone (Auto Collect).
function FarmLogic.isInAutoCollectZone(
    dropX: number,
    dropY: number,
    dropZ: number,
    tipX: number,
    tipY: number,
    tipZ: number,
    radius: number
): boolean
    local dx = dropX - tipX
    local dy = dropY - tipY
    local dz = dropZ - tipZ
    local r = math.max(0, radius)
    return dx * dx + dy * dy + dz * dz <= r * r
end

return FarmLogic
