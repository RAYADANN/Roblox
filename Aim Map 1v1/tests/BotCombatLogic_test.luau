local BotCombatLogic = require("@shared/util/BotCombatLogic")
local Constants = require("@shared/data/Constants")

local function constRng(value: number): () -> number
    return function()
        return value
    end
end

return {
    ["isBotUserId"] = function(expect)
        expect(BotCombatLogic.isBotUserId(Constants.BOT_USER_ID)).toEqual(true)
        expect(BotCombatLogic.isBotUserId(1)).toEqual(false)
    end,

    ["moveBand by distance"] = function(expect)
        expect(BotCombatLogic.moveBand(10)).toEqual("retreat")
        expect(BotCombatLogic.moveBand(40)).toEqual("hold")
        expect(BotCombatLogic.moveBand(80)).toEqual("advance")
    end,

    ["strafeSign alternates"] = function(expect)
        expect(BotCombatLogic.strafeSign(0, 1)).toEqual(1)
        expect(BotCombatLogic.strafeSign(1.1, 1)).toEqual(-1)
        expect(BotCombatLogic.strafeSign(2.1, 1)).toEqual(1)
    end,

    ["moveDirection advance goes toward target"] = function(expect)
        local bot = BotCombatLogic.vec(0, 0, 0)
        local target = BotCombatLogic.vec(50, 0, 0)
        local dir = BotCombatLogic.moveDirection(bot, target, "advance", 1)
        expect(dir.x > 0).toEqual(true)
    end,

    ["rollReaction in range"] = function(expect)
        local lo = BotCombatLogic.rollReaction(constRng(0))
        local hi = BotCombatLogic.rollReaction(constRng(1))
        expect(lo).toEqual(Constants.BOT_REACTION_MIN_SEC)
        expect(hi).toEqual(Constants.BOT_REACTION_MAX_SEC)
    end,

    ["aimWithError stays near true direction"] = function(expect)
        local from = BotCombatLogic.vec(0, 0, 0)
        local to = BotCombatLogic.vec(0, 0, -100)
        local perfect = BotCombatLogic.aimWithError(from, to, 0, constRng(0.5))
        expect(BotCombatLogic.dot(perfect, BotCombatLogic.vec(0, 0, -1)) > 0.99).toEqual(true)

        local skewed = BotCombatLogic.aimWithError(from, to, 0.05, constRng(0.9))
        expect(BotCombatLogic.dot(skewed, BotCombatLogic.vec(0, 0, -1)) > 0.9).toEqual(true)
    end,
    ["aimWithError from offset muzzle still points at target"] = function(expect)
        -- Chest origin vs Shoot offset must not be mixed: direction is muzzle → target.
        local muzzle = BotCombatLogic.vec(1.8, 0.5, 0)
        local target = BotCombatLogic.vec(0, 2, -40)
        local dir = BotCombatLogic.aimWithError(muzzle, target, 0, constRng(0.5))
        local expected = BotCombatLogic.vec(0 - 1.8, 2 - 0.5, -40)
        local mag = math.sqrt(expected.x ^ 2 + expected.y ^ 2 + expected.z ^ 2)
        expected = BotCombatLogic.vec(expected.x / mag, expected.y / mag, expected.z / mag)
        expect(BotCombatLogic.dot(dir, expected)).toBeCloseTo(1, 1e-6)
    end,

    ["canFire gates on los reaction cooldown"] = function(expect)
        expect(BotCombatLogic.canFire(false, 1, 0.2, 1, 0.22)).toEqual(false)
        expect(BotCombatLogic.canFire(true, 0.1, 0.2, 1, 0.22)).toEqual(false)
        expect(BotCombatLogic.canFire(true, 0.3, 0.2, 0.1, 0.22)).toEqual(false)
        expect(BotCombatLogic.canFire(true, 0.3, 0.2, 0.3, 0.22)).toEqual(true)
    end,

    ["rememberTarget uses memory window"] = function(expect)
        expect(BotCombatLogic.rememberTarget(true, 99, 1.2)).toEqual(true)
        expect(BotCombatLogic.rememberTarget(false, 0.5, 1.2)).toEqual(true)
        expect(BotCombatLogic.rememberTarget(false, 2, 1.2)).toEqual(false)
    end,

    ["rollFireCooldown above base"] = function(expect)
        local lo = BotCombatLogic.rollFireCooldown(constRng(0))
        local hi = BotCombatLogic.rollFireCooldown(constRng(1))
        expect(lo).toEqual(Constants.BOT_FIRE_COOLDOWN_SEC)
        expect(hi).toEqual(Constants.BOT_FIRE_COOLDOWN_SEC + Constants.BOT_FIRE_JITTER_SEC)
    end,
}
