--!strict

local ColorSheenLogic = require("../src/shared/util/ColorSheenLogic")

local sampleKeys = {
    { t = 0, c = { r = 255, g = 255, b = 0 } },
    { t = 1, c = { r = 255, g = 85, b = 0 } },
}

return {
    ["variantCount is 16"] = function(expect)
        expect(ColorSheenLogic.variantCount()).toEqual(16)
    end,

    ["S1 hard sweep starts at -1"] = function(expect)
        local p = ColorSheenLogic.pose(1, 0, 90, sampleKeys)
        expect(p.offset.x).toEqual(-1)
        expect(p.rotation).toEqual(90)
    end,

    ["S9 white band returns keys"] = function(expect)
        local p = ColorSheenLogic.pose(9, 0.2, 0, sampleKeys)
        expect(p.keys ~= nil).toBeTruthy()
        expect(#(p.keys :: any) > 2).toBeTruthy()
    end,

    ["S10 hue shift returns keys"] = function(expect)
        local p = ColorSheenLogic.pose(10, 1.0, 0, sampleKeys)
        expect(p.keys ~= nil).toBeTruthy()
    end,

    ["S11 rainbow is solid"] = function(expect)
        local p = ColorSheenLogic.pose(11, 0.5, 0, sampleKeys)
        expect(p.solid ~= nil).toBeTruthy()
    end,

    ["S15 candy has keys and spin"] = function(expect)
        local a = ColorSheenLogic.pose(15, 0, 0, sampleKeys)
        local b = ColorSheenLogic.pose(15, 1, 0, sampleKeys)
        expect(a.keys ~= nil).toBeTruthy()
        expect(a.rotation ~= b.rotation).toBeTruthy()
    end,

    ["labels cover 1..16"] = function(expect)
        local labels = ColorSheenLogic.labels()
        for i = 1, 16 do
            expect(typeof(labels[i])).toEqual("string")
        end
    end,
}
