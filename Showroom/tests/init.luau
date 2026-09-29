--!strict
-- Лёгкий тест-раннер под Lune. Запуск: `lune run tests`.

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
    { name = "ExhibitLogic", tests = require("./ExhibitLogic.test") },
    { name = "FavoriteLogic", tests = require("./FavoriteLogic.test") },
    { name = "AuctionLogic", tests = require("./AuctionLogic.test") },
    { name = "AttentionLogic", tests = require("./AttentionLogic.test") },
    { name = "MutationLogic", tests = require("./MutationLogic.test") },
    { name = "OfferRouletteLogic", tests = require("./OfferRouletteLogic.test") },
    { name = "buildHudPayload", tests = require("./buildHudPayload.test") },
    { name = "FormatMoney", tests = require("./FormatMoney.test") },
    { name = "IndexLogic", tests = require("./IndexLogic.test") },
    { name = "InventoryBarLogic", tests = require("./InventoryBarLogic.test") },
    { name = "ShopLogic", tests = require("./ShopLogic.test") },
    { name = "RebirthLogic", tests = require("./RebirthLogic.test") },
    { name = "UiAdaptLogic", tests = require("./UiAdaptLogic.test") },
    { name = "PlayerAttributeSync", tests = require("./PlayerAttributeSync.test") },
    { name = "QualityLogic", tests = require("./QualityLogic.test") },
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
