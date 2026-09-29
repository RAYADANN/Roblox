--!strict
-- Формулы апгрейдов (единый источник для сервера и клиента).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)
local RebirthLogic = require(ReplicatedStorage:WaitForChild("shared").util.RebirthLogic)
local NumberFormat = require(ReplicatedStorage:WaitForChild("shared").util.NumberFormat)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local UpgradeLogic = {}

-- Phase 9: maxLevel у pickaxe растёт на +1 за каждый пройденный порог в
-- Constants.REBIRTH.pickaxeMaxBonusAt (R5/R10/R25 → +1/+2/+3). Остальные
-- апгрейды rebirth-инвариантны: их maxLevel = cfg.maxLevel.
--
-- Параметр `rebirths` опционален: если не передан — возвращаем «голый»
-- maxLevel из Constants (поведение до Phase 9). Это позволяет вызывать
-- UpgradeLogic.maxLevel(id) из мест, где ребёрты ещё не подгружены
-- (логи, дебаг) без падения.
function UpgradeLogic.maxLevel(upgradeId: string, rebirths: number?): number
    local cfg = Constants.UPGRADES[upgradeId]
    if not cfg then
        return 0
    end
    local base = cfg.maxLevel or 0
    if upgradeId == "pickaxe" then
        return base + RebirthLogic.pickaxeMaxLevelBonus(rebirths or 0)
    end
    return base
end

function UpgradeLogic.upgradeCost(upgradeId: string, currentLevel: number): number
    local cfg = Constants.UPGRADES[upgradeId]
    if not cfg then
        return 0
    end
    return math.floor(cfg.baseCost * ((cfg.exponent or 1.5) ^ (currentLevel - 1)))
end

-- P1.7: мультипликативное (diminishing) снижение задержки удара. Каждый
-- уровень множит задержку на (1 - reductionPct), поэтому пол достигается
-- асимптотически — ни один из 50 уровней не «мёртвый». Fallback на старый
-- линейный reductionMs оставлен на случай отсутствия reductionPct в конфиге.
function UpgradeLogic.swingDelaySeconds(speedLevel: number, speedBoostMult: number?): number
    local cfg = Constants.UPGRADES.speed
    local level = math.max(1, speedLevel)
    local baseSeconds = Constants.BASE_SWING_DELAY_MS / 1000
    local delay: number
    if cfg.reductionPct then
        delay = baseSeconds * ((1 - cfg.reductionPct) ^ (level - 1))
    else
        local reductionMs = cfg.reductionMs or 20
        delay = (Constants.BASE_SWING_DELAY_MS - (level - 1) * reductionMs) / 1000
    end
    delay = math.max(Constants.MIN_SWING_DELAY_SECONDS, delay)
    local mult = speedBoostMult or 1
    if mult > 1 then
        delay = delay / mult
    end
    return math.max(Constants.MIN_SWING_DELAY_SECONDS, delay)
end

-- Мультипликатор скорости копания из HUD-payload activeBoosts (клиент).
function UpgradeLogic.speedBoostMultiplier(activeBoosts: { any }?): number
    if not activeBoosts then
        return 1
    end
    local sum = 0
    for _, boost in ipairs(activeBoosts) do
        if typeof(boost) == "table"
            and boost.kind == "speed"
            and (boost.remaining or 0) > 0
        then
            sum += (boost.multiplier or 1) - 1
        end
    end
    return 1 + sum
end

function UpgradeLogic.pickaxePower(pickaxeLevel: number): number
    local cfg = Constants.UPGRADES.pickaxe
    return 1 + (math.max(1, pickaxeLevel) - 1) * (cfg.powerPerLevel or 2)
end

function UpgradeLogic.critChance(critLevel: number): number
    local cfg = Constants.UPGRADES.crit
    local base = cfg.baseChance or 0.05
    local perLevel = cfg.chancePerLevel or 0.03
    return base + (math.max(1, critLevel) - 1) * perLevel
end

function UpgradeLogic.fortuneBonusChance(fortuneLevel: number): number
    local cfg = Constants.UPGRADES.fortune
    return (math.max(1, fortuneLevel) - 1) * (cfg.chancePerLevel or 0.02)
end

-- P1.4: ребёрт добавляет постоянные слоты рюкзака (RebirthLogic.inventorySlotBonus).
-- `rebirths` опционален (default 0) — старые вызовы без ребёртов не ломаются.
function UpgradeLogic.inventoryCapacity(inventoryLevel: number, rebirths: number?): number
    local cfg = Constants.UPGRADES.inventory
    local base = Constants.BASE_INVENTORY_SLOTS + math.max(1, inventoryLevel) * (cfg.slotsPerLevel or 5)
    return base + RebirthLogic.inventorySlotBonus(rebirths or 0)
end

function UpgradeLogic.multiSellMultiplier(multiSellLevel: number): number
    local cfg = Constants.UPGRADES.multiSell
    local level = math.max(1, multiSellLevel)
    return 1 + (level - 1) * (cfg.bonusPerLevel or 0.05)
end

function UpgradeLogic.levelField(upgradeId: string): string?
    if upgradeId == "autoSell" then
        return nil
    end
    return upgradeId .. "Level"
end

-- Phase 8: читаемое описание изменения, которое даст следующий уровень
-- апгрейда. Используется для hover-tooltip в HUD ("Сейчас: …, Далее: …").
-- Возвращает строки в формате "урон 11 → 13" / "+9% удачи" / "20 → 25 слотов".
local function formatSeconds(value: number): string
    return L("upgrade.unit.seconds", { value = NumberFormat.decimal(value, 1) })
end

local function formatPercent(value: number): string
    return ("%d%%"):format(math.floor(value * 100 + 0.5))
end

function UpgradeLogic.describeCurrentLevel(upgradeId: string, currentLevel: number): string
    local lvl = math.max(1, currentLevel)
    if upgradeId == "pickaxe" then
        return L("upgrade.pickaxe.current", { value = UpgradeLogic.pickaxePower(lvl) })
    elseif upgradeId == "speed" then
        return L("upgrade.speed.current", { value = formatSeconds(UpgradeLogic.swingDelaySeconds(lvl)) })
    elseif upgradeId == "fortune" then
        return L("upgrade.fortune.current", { value = formatPercent(UpgradeLogic.fortuneBonusChance(lvl)) })
    elseif upgradeId == "inventory" then
        return L("upgrade.inventory.current", { value = UpgradeLogic.inventoryCapacity(lvl) })
    elseif upgradeId == "crit" then
        return L("upgrade.crit.current", { value = formatPercent(UpgradeLogic.critChance(lvl)) })
    elseif upgradeId == "multiSell" then
        local mult = UpgradeLogic.multiSellMultiplier(lvl)
        return L("upgrade.multiSell.current", { value = formatPercent(mult - 1) })
    elseif upgradeId == "autoSell" then
        return if currentLevel >= 1 then L("upgrade.autoSell.on") else L("upgrade.autoSell.off")
    end
    return "—"
end

function UpgradeLogic.describeNextLevel(upgradeId: string, currentLevel: number, rebirths: number?): string?
    if upgradeId == "autoSell" then
        return if currentLevel >= 1 then nil else L("upgrade.autoSell.next")
    end
    local cfg = Constants.UPGRADES[upgradeId]
    if not cfg then
        return nil
    end
    -- Phase 9: pickaxe.maxLevel динамический (+1 за каждый перейденный
    -- ребёрт-порог). Без rebirths-арга после R5 tooltip всё ещё писал бы
    -- «нет улучшений», хотя сервер уже принял бы покупку.
    local effectiveMax = UpgradeLogic.maxLevel(upgradeId, rebirths or 0)
    if currentLevel >= effectiveMax then
        return nil
    end
    local nextLevel = currentLevel + 1
    if upgradeId == "pickaxe" then
        return L("upgrade.pickaxe.next", {
            from = UpgradeLogic.pickaxePower(currentLevel),
            to = UpgradeLogic.pickaxePower(nextLevel),
        })
    elseif upgradeId == "speed" then
        return L("upgrade.speed.next", {
            from = formatSeconds(UpgradeLogic.swingDelaySeconds(currentLevel)),
            to = formatSeconds(UpgradeLogic.swingDelaySeconds(nextLevel)),
        })
    elseif upgradeId == "fortune" then
        return L("upgrade.fortune.next", {
            from = formatPercent(UpgradeLogic.fortuneBonusChance(currentLevel)),
            to = formatPercent(UpgradeLogic.fortuneBonusChance(nextLevel)),
        })
    elseif upgradeId == "inventory" then
        return L("upgrade.inventory.next", {
            from = UpgradeLogic.inventoryCapacity(currentLevel),
            to = UpgradeLogic.inventoryCapacity(nextLevel),
        })
    elseif upgradeId == "crit" then
        return L("upgrade.crit.next", {
            from = formatPercent(UpgradeLogic.critChance(currentLevel)),
            to = formatPercent(UpgradeLogic.critChance(nextLevel)),
        })
    elseif upgradeId == "multiSell" then
        return L("upgrade.multiSell.next", {
            from = formatPercent(UpgradeLogic.multiSellMultiplier(currentLevel) - 1),
            to = formatPercent(UpgradeLogic.multiSellMultiplier(nextLevel) - 1),
        })
    end
    return nil
end

return UpgradeLogic
