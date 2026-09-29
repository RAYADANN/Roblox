--!strict
local PickupScoreLogic = require("../src/shared/util/PickupScoreLogic")
local ScoreGradientCatalog = require("../src/shared/data/ScoreGradientCatalog")

return {
    ["encode/decode roundtrip"] = function(expect)
        local payload = PickupScoreLogic.encode("diamond", 20)
        local kind, value = PickupScoreLogic.decode(payload)
        expect(kind).toEqual("diamond")
        expect(value).toEqual(20)
    end,

    ["normal shows plus value"] = function(expect)
        local spec = PickupScoreLogic.spec("normal", 1, 1)
        expect(spec.text).toEqual("+1")
        expect(spec.isRare).toEqual(false)
        expect(spec.textSize).toEqual(63)
        expect(spec.gradientId).toEqual(ScoreGradientCatalog.at(1).id)
    end,

    ["rare diamond shows plus value"] = function(expect)
        local spec = PickupScoreLogic.spec("diamond", 20, 3)
        expect(spec.text).toEqual("+20")
        expect(spec.isRare).toEqual(true)
        expect(spec.textSize).toEqual(108)
        expect(spec.gradientId).toEqual(ScoreGradientCatalog.at(3).id)
    end,

    ["gradient follows index not drop kind"] = function(expect)
        local a = PickupScoreLogic.spec("normal", 1, 5)
        local b = PickupScoreLogic.spec("diamond", 10, 5)
        expect(a.gradientId).toEqual(b.gradientId)
        expect(a.gradientId).toEqual(ScoreGradientCatalog.at(5).id)
    end,

    ["gradients share 0 / 0.5 / 1 stops"] = function(expect)
        expect(ScoreGradientCatalog.count() > 10).toEqual(true)
        for _, def in ScoreGradientCatalog.all() do
            expect(#def.stops).toEqual(3)
            expect(def.stops[1].t).toEqual(0)
            expect(def.stops[2].t).toEqual(0.5)
            expect(def.stops[3].t).toEqual(1)
        end
    end,

    ["random gradient uses seeded rng"] = function(expect)
        local rolls = { 0, 0.99 }
        local i = 0
        local rng = function()
            i += 1
            return rolls[i] or 0
        end
        expect(ScoreGradientCatalog.random(rng).id).toEqual(ScoreGradientCatalog.at(1).id)
        expect(ScoreGradientCatalog.random(rng).id).toEqual(
            ScoreGradientCatalog.at(ScoreGradientCatalog.count()).id
        )
    end,
}
