return {
    ["unpack progress reaches 1"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        expect(ContainerLogic.unpackProgress(0, "common")).toEqual(0)
        expect(ContainerLogic.unpackProgress(12, "common")).toEqual(1)
        expect(ContainerLogic.unpackProgress(6, "common")).toBeCloseTo(0.5, 0.01)
    end,
    ["buy price grows with rarity"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local common = ContainerLogic.buyPrice("common", 0)
        local rare = ContainerLogic.buyPrice("rare", 0)
        expect(rare > common).toBeTruthy()
    end,
    ["mutation boosts income"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local base = ContainerLogic.incomePerMini("common", {})
        local gold = ContainerLogic.incomePerMini("common", { "golden" })
        expect(gold > base).toBeTruthy()
    end,
}
