--!strict
local StyleTokens = require("../src/shared/vfx/StyleTokens")

return {
    ["palette: neon rgb"] = function(expect)
        local n = StyleTokens.rgb("neon")
        expect(#n).toEqual(3)
        expect(n[2] > n[1]).toBeTruthy()
    end,

    ["timing: peak after flash"] = function(expect)
        expect(StyleTokens.timing.peak > StyleTokens.timing.flash).toBeTruthy()
        expect(StyleTokens.timing.recovery > StyleTokens.timing.peak).toBeTruthy()
    end,
}
