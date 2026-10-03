--!strict
local TutorialLogic = require("../src/shared/util/TutorialLogic")

local function snap(overrides: { [string]: any }?): TutorialLogic.Snapshot
    local base: TutorialLogic.Snapshot = {
        didRoll = false,
        didBuy = false,
        didPlace = false,
        hasReady = false,
        didOpen = false,
        hasSellBoxCoins = false,
        didTake = false,
        didSell = false,
    }
    if overrides then
        for k, v in overrides do
            (base :: any)[k] = v
        end
    end
    return base
end

return {
    ["resolveStep: starts at roll"] = function(expect)
        expect(TutorialLogic.resolveStep(snap())).toEqual(1)
    end,
    ["resolveStep: after roll stays on buy without didBuy"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({ didRoll = true }))).toEqual(2)
    end,
    ["resolveStep: leftover inventory does not skip buy"] = function(expect)
        -- Old bug: hasContainer/slots made buy look done after roll.
        expect(TutorialLogic.resolveStep(snap({ didRoll = true }))).toEqual(2)
    end,
    ["resolveStep: after buy goes to place"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({ didRoll = true, didBuy = true }))).toEqual(3)
    end,
    ["resolveStep: after place goes to wait_ready"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({
            didRoll = true,
            didBuy = true,
            didPlace = true,
        }))).toEqual(4)
    end,
    ["resolveStep: ready goes to open"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({
            didRoll = true,
            didBuy = true,
            didPlace = true,
            hasReady = true,
        }))).toEqual(5)
    end,
    ["resolveStep: opened goes to wait_path"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({
            didRoll = true,
            didBuy = true,
            didPlace = true,
            didOpen = true,
        }))).toEqual(6)
    end,
    ["resolveStep: path done goes to take"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({
            didRoll = true,
            didBuy = true,
            didPlace = true,
            didOpen = true,
            hasSellBoxCoins = true,
        }))).toEqual(7)
    end,
    ["resolveStep: taken goes to sell"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({
            didRoll = true,
            didBuy = true,
            didPlace = true,
            didOpen = true,
            didTake = true,
        }))).toEqual(8)
    end,
    ["resolveStep: sold completes"] = function(expect)
        expect(TutorialLogic.resolveStep(snap({
            didRoll = true,
            didBuy = true,
            didPlace = true,
            didOpen = true,
            didTake = true,
            didSell = true,
        }))).toEqual(0)
    end,
    ["advanceOne: after roll only moves to buy"] = function(expect)
        expect(TutorialLogic.advanceOne(1, snap({ didRoll = true }))).toEqual(2)
    end,
    ["getStep: buy is step 2"] = function(expect)
        local s = TutorialLogic.getStep(2)
        expect(s ~= nil).toBeTruthy()
        expect(s and s.target).toEqual("buy")
    end,
}
