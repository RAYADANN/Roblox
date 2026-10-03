--!strict

local Constants
local UpgradeDatabase
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
    UpgradeDatabase = require(script.Parent.Parent.data.UpgradeDatabase)
else
    Constants = require("../data/Constants")
    UpgradeDatabase = require("../data/UpgradeDatabase")
end

type UpgradeId = UpgradeDatabase.UpgradeId
type UpgradeLevels = { [string]: number }

local UpgradeLogic = {}

function UpgradeLogic.cost(upgradeId: string, level: number): number?
    local entry = UpgradeDatabase.get(upgradeId)
    if not entry then
        return nil
    end
    local growth = entry.costGrowth
    if typeof(growth) ~= "number" or growth <= 1 then
        growth = Constants.UPGRADE_COST_MULT
    end
    return math.floor(entry.baseCost * growth ^ level)
end

function UpgradeLogic.robuxCost(upgradeId: string): number?
    local entry = UpgradeDatabase.get(upgradeId)
    if not entry then
        return nil
    end
    return entry.robuxCost
end

function UpgradeLogic.productId(upgradeId: string): number?
    local entry = UpgradeDatabase.get(upgradeId)
    if not entry then
        return nil
    end
    local id = entry.productId
    if typeof(id) ~= "number" or id <= 0 then
        return nil
    end
    return id
end

function UpgradeLogic.idFromProductId(productId: number): string?
    local entry = UpgradeDatabase.getByProductId(productId)
    if not entry then
        return nil
    end
    return entry.id
end

function UpgradeLogic.canAfford(coins: number, cost: number): boolean
    return coins >= cost
end

function UpgradeLogic.isMaxLevel(upgradeId: string, level: number): boolean
    local entry = UpgradeDatabase.get(upgradeId)
    if not entry then
        return true
    end
    return level >= entry.maxLevel
end

function UpgradeLogic.isValidId(upgradeId: string): boolean
    return UpgradeDatabase.get(upgradeId) ~= nil
end

function UpgradeLogic.statusText(upgradeId: string, level: number): string
    local entry = UpgradeDatabase.get(upgradeId)
    if not entry then
        return "Current: —"
    end
    return entry.statusAtLevel(level)
end

function UpgradeLogic.ordered(): { UpgradeDatabase.UpgradeEntry }
    return UpgradeDatabase.ordered()
end

local function levelOf(upgrades: UpgradeLevels?, id: string): number
    if not upgrades then
        return 0
    end
    return math.max(0, math.floor(tonumber(upgrades[id]) or 0))
end

--- Unlocked HeroPlace count: starts at 10, +1 per Base Expansion level.
function UpgradeLogic.unlockedSlots(upgrades: UpgradeLevels?): number
    local baseLevel = levelOf(upgrades, "base")
    local n = Constants.BASE_UNLOCKED_SLOTS + baseLevel
    return math.clamp(n, Constants.BASE_UNLOCKED_SLOTS, Constants.SLOT_COUNT)
end

function UpgradeLogic.isSlotUnlocked(upgrades: UpgradeLevels?, slotIndex: number): boolean
    local idx = math.floor(slotIndex)
    return idx >= 1 and idx <= UpgradeLogic.unlockedSlots(upgrades)
end

--- Stand pads (Stand1..5): starts at 1, +1 per Pad Unlock level (max 5).
function UpgradeLogic.unlockedPads(upgrades: UpgradeLevels?): number
    local padLevel = levelOf(upgrades, "pad")
    local n = Constants.BASE_UNLOCKED_PADS + padLevel
    return math.clamp(n, Constants.BASE_UNLOCKED_PADS, Constants.OFFER_COUNT)
end

function UpgradeLogic.isPadUnlocked(upgrades: UpgradeLevels?, padIndex: number): boolean
    local idx = math.floor(padIndex)
    return idx >= 1 and idx <= UpgradeLogic.unlockedPads(upgrades)
end

--- Floor 1 always; floor 2 when slots>10; floor 3 when slots>20.
function UpgradeLogic.isFloorUnlocked(upgrades: UpgradeLevels?, floorIndex: number): boolean
    local floor = math.floor(floorIndex)
    if floor <= 1 then
        return true
    end
    if floor > Constants.FLOOR_COUNT then
        return false
    end
    local unlocked = UpgradeLogic.unlockedSlots(upgrades)
    return unlocked > (floor - 1) * Constants.SLOTS_PER_FLOOR
end

--- Cash Boost: +10% sell payout per level.
function UpgradeLogic.cashMultiplier(upgrades: UpgradeLevels?): number
    return 1 + levelOf(upgrades, "cash") * 0.1
end

--- Time Boost: −1% unpack duration per level (floor 50%).
function UpgradeLogic.unpackTimeMultiplier(upgrades: UpgradeLevels?): number
    local mult = 1 - levelOf(upgrades, "time") * 0.01
    return math.clamp(mult, 0.5, 1)
end

--- Luck: Luck Boost (+15%/lvl) + Pad Upgrade (+20%/lvl).
function UpgradeLogic.luckBias(upgrades: UpgradeLevels?): number
    return levelOf(upgrades, "luck") * 0.15 + levelOf(upgrades, "padTier") * 0.2
end

--- Pad visual tier: 0 = authored Stand, 1..3 = Stand2LVL..Stand4LVL.
function UpgradeLogic.padTierLevel(upgrades: UpgradeLevels?): number
    return math.clamp(levelOf(upgrades, "padTier"), 0, 3)
end

--- Template name under ReplicatedStorage.GameAssets.Stands (nil = keep authored).
function UpgradeLogic.padTierTemplateName(upgrades: UpgradeLevels?): string?
    local tier = UpgradeLogic.padTierLevel(upgrades)
    if tier <= 0 then
        return nil
    end
    local names = { "Stand2LVL", "Stand3LVL", "Stand4LVL" }
    return names[tier]
end

--- Speed Boost: WalkSpeed = 16 + 0.5 per level.
function UpgradeLogic.walkSpeed(upgrades: UpgradeLevels?): number
    return 16 + levelOf(upgrades, "speed") * 0.5
end

return UpgradeLogic
