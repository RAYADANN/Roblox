return {
    ["stand level maps to box shape"] = function(expect)
        local BoxVisualLogic = require("../src/shared/util/BoxVisualLogic")
        expect(BoxVisualLogic.shapeForStandLevel(1)).toEqual("1")
        expect(BoxVisualLogic.shapeForStandLevel(2)).toEqual("2")
        expect(BoxVisualLogic.shapeForStandLevel(3)).toEqual("3")
        expect(BoxVisualLogic.shapeForStandLevel(4)).toEqual("3")
    end,
    ["palette pick is deterministic for rng"] = function(expect)
        local BoxVisualLogic = require("../src/shared/util/BoxVisualLogic")
        local a = BoxVisualLogic.pickBoxModelName(1, 0)
        local b = BoxVisualLogic.pickBoxModelName(1, 0)
        expect(a).toEqual(b)
        expect(string.find(a, "Box1_", 1, true) ~= nil).toBeTruthy()
        local c = BoxVisualLogic.pickBoxModelName(2, 0)
        expect(string.find(c, "BoxLVL2_", 1, true) ~= nil).toBeTruthy()
        local d = BoxVisualLogic.pickBoxModelName(3, 0)
        expect(string.find(d, "Diamond_", 1, true) ~= nil).toBeTruthy()
    end,
    ["case display names are brainrot"] = function(expect)
        local BoxVisualLogic = require("../src/shared/util/BoxVisualLogic")
        expect(BoxVisualLogic.formatCaseDisplayName("Box1_MintIce", 1)).toEqual("Menta Gelato")
        expect(BoxVisualLogic.formatCaseDisplayName("Diamond_Obsidian", 3)).toEqual(
            "Nero Cappuccino"
        )
        expect(BoxVisualLogic.formatCaseDisplayName("BoxLVL2_Sapphire", 2)).toEqual(
            "Blu Blu Mareini"
        )
    end,
    ["luck maps to stand mesh tier"] = function(expect)
        local BoxVisualLogic = require("../src/shared/util/BoxVisualLogic")
        expect(BoxVisualLogic.standLevelFromLuck(0)).toEqual(1)
        expect(BoxVisualLogic.standLevelFromLuck(3)).toEqual(2)
        expect(BoxVisualLogic.standLevelFromLuck(6)).toEqual(3)
    end,
    ["hero pick stays inside rarity pool"] = function(expect)
        local ContainerLogic = require("../src/shared/util/ContainerLogic")
        local HeroCatalog = require("../src/shared/data/HeroCatalog")
        local pool = HeroCatalog.pool("mythic")
        local id = ContainerLogic.pickHeroId("mythic", 0.5)
        local found = false
        for _, name in pool do
            if name == id then
                found = true
                break
            end
        end
        expect(found).toBeTruthy()
    end,
    ["mutation visual resolves golden"] = function(expect)
        local MutationVisualDatabase = require("../src/shared/data/MutationVisualDatabase")
        local def = MutationVisualDatabase.resolveFromStack({ "golden" })
        expect(def ~= nil).toBeTruthy()
        expect(def.effectModelName).toEqual("Gold")
        expect(MutationVisualDatabase.HERO_FX_SCALE).toEqual(1.1)
    end,
}
