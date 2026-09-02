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

-- CI pins Lune 0.8.9: relative ./ from init resolves siblings. (0.10 needs @self/)
local MODULES: { { name: string, tests: { [string]: TestFn } } } = {
    { name = "RebirthLogic", tests = require("./RebirthLogic_test") },
    { name = "UpgradeLogic", tests = require("./UpgradeLogic_test") },
    { name = "MatchLogic", tests = require("./MatchLogic_test") },
    { name = "BotCombatLogic", tests = require("./BotCombatLogic_test") },
    { name = "CrosshairLogic", tests = require("./CrosshairLogic_test") },
    { name = "WeaponLogic", tests = require("./WeaponLogic_test") },
    { name = "RagdollLogic", tests = require("./RagdollLogic_test") },
    { name = "CombatAudioLogic", tests = require("./CombatAudioLogic_test") },
    { name = "DamageIndicatorLogic", tests = require("./DamageIndicatorLogic_test") },
    { name = "CombatFlashLogic", tests = require("./CombatFlashLogic_test") },
    { name = "HitMarkerLogic", tests = require("./HitMarkerLogic_test") },
    { name = "RecoilLogic", tests = require("./RecoilLogic_test") },
    { name = "KillFlexLogic", tests = require("./KillFlexLogic_test") },
    { name = "SkinDatabase", tests = require("./SkinDatabase_test") },
    { name = "RarityLogic", tests = require("./RarityLogic_test") },
    { name = "InventoryGridLogic", tests = require("./InventoryGridLogic_test") },
    { name = "UiAdaptLogic", tests = require("./UiAdaptLogic_test") },
    { name = "TracerLogic", tests = require("./TracerLogic_test") },
    { name = "SensitivityLogic", tests = require("./SensitivityLogic_test") },
    { name = "buildHudPayload", tests = require("./buildHudPayload_test") },
    { name = "PlayerAttributeSync", tests = require("./PlayerAttributeSync_test") },
    { name = "QualityLogic", tests = require("./QualityLogic_test") },
    { name = "AssetPreloadLogic", tests = require("./AssetPreloadLogic_test") },
    { name = "FootstepLogic", tests = require("./FootstepLogic_test") },
    { name = "RigAnimLogic", tests = require("./RigAnimLogic_test") },
    { name = "R15LocomotionDatabase", tests = require("./R15LocomotionDatabase_test") },
    { name = "UspVisualLogic", tests = require("./UspVisualLogic_test") },
    { name = "LookAimLogic", tests = require("./LookAimLogic_test") },
    { name = "ViewModelLogic", tests = require("./ViewModelLogic_test") },
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
