--!strict
-- Лёгкий тест-раннер под Lune. Запуск: `lune run tests`.
-- Добавляя новый *.test.luau — допиши его в реестр MODULES ниже.
-- Deep-сравнение таблиц НЕ делается: сравнивай примитивы (числа/строки/bool).

local process = require("@lune/process")

type Assertions = {
    toEqual: (expected: any) -> (),
    toBe: (expected: any) -> (),
    toBeTruthy: () -> (),
    toBeFalsy: () -> (),
    toBeCloseTo: (expected: number, tolerance: number?) -> (),
}
type Expect = (value: any) -> Assertions
type TestFn = (Expect) -> ()

local function makeExpect(fail: (msg: string) -> ()): Expect
    return function(value: any): Assertions
        return {
            toEqual = function(expected)
                if value ~= expected then
                    fail(`expected {tostring(expected)}, got {tostring(value)}`)
                end
            end,
            toBe = function(expected)
                if value ~= expected then
                    fail(`expected {tostring(expected)}, got {tostring(value)}`)
                end
            end,
            toBeTruthy = function()
                if not value then
                    fail(`expected truthy, got {tostring(value)}`)
                end
            end,
            toBeFalsy = function()
                if value then
                    fail(`expected falsy, got {tostring(value)}`)
                end
            end,
            toBeCloseTo = function(expected, tolerance)
                local tol = tolerance or 1e-6
                if math.abs(value - expected) > tol then
                    fail(`expected ~{expected} (±{tol}), got {tostring(value)}`)
                end
            end,
        }
    end
end

local MODULES: { { name: string, tests: { [string]: TestFn } } } = {
    { name = "RebirthLogic", tests = require("./RebirthLogic.test") },
    { name = "UpgradeLogic", tests = require("./UpgradeLogic.test") },
    { name = "buildHudPayload", tests = require("./buildHudPayload.test") },
    { name = "PlayerAttributeSync", tests = require("./PlayerAttributeSync.test") },
    { name = "QualityLogic", tests = require("./QualityLogic.test") },
    { name = "ContainerLogic", tests = require("./ContainerLogic.test") },
    { name = "HeroLevelLogic", tests = require("./HeroLevelLogic.test") },
    { name = "BoxHeroContentLogic", tests = require("./BoxHeroContentLogic.test") },
    { name = "MutationLogic", tests = require("./MutationLogic.test") },
    { name = "MutationShineLogic", tests = require("./MutationShineLogic.test") },
    { name = "MutationShineDatabase", tests = require("./MutationShineDatabase.test") },
    { name = "RarityShineLogic", tests = require("./RarityShineLogic.test") },
    { name = "RarityShineDatabase", tests = require("./RarityShineDatabase.test") },
    { name = "OfferRouletteLogic", tests = require("./OfferRouletteLogic.test") },
    { name = "ConveyorLogic", tests = require("./ConveyorLogic.test") },
    { name = "SellBoxLogic", tests = require("./SellBoxLogic.test") },
    { name = "HeroScaleLogic", tests = require("./HeroScaleLogic.test") },
    { name = "ContainerPlacementLogic", tests = require("./ContainerPlacementLogic.test") },
    { name = "HeroCatalog", tests = require("./HeroCatalog.test") },
    { name = "IndexLogic", tests = require("./IndexLogic.test") },
    { name = "LimitedLogic", tests = require("./LimitedLogic.test") },
    { name = "BoostOfferLogic", tests = require("./BoostOfferLogic.test") },
    { name = "BaseClaimLogic", tests = require("./BaseClaimLogic.test") },
    { name = "SlotMap", tests = require("./SlotMap.test") },
    { name = "OfflineEarningsLogic", tests = require("./OfflineEarningsLogic.test") },
    { name = "RewardTrackLogic", tests = require("./RewardTrackLogic.test") },
    { name = "TextFxLogic", tests = require("./TextFxLogic.test") },
    { name = "ColorSheenLogic", tests = require("./ColorSheenLogic.test") },
    { name = "TutorialFocusLogic", tests = require("./TutorialFocusLogic.test") },
    { name = "TutorialLogic", tests = require("./TutorialLogic.test") },
}

local passed, failed = 0, 0
for _, mod in MODULES do
    for name, testFn in mod.tests do
        local failMsg: string? = nil
        local expect = makeExpect(function(m)
            failMsg = m
        end)
        local ok, err = pcall(testFn, expect)
        if not ok then
            failed += 1
            print(`✗ {mod.name} > {name}: {tostring(err)}`)
        elseif failMsg then
            failed += 1
            print(`✗ {mod.name} > {name}: {failMsg}`)
        else
            passed += 1
            print(`✓ {mod.name} > {name}`)
        end
    end
end

print(`\n{passed} passed, {failed} failed`)
if failed > 0 then
    process.exit(1)
end
