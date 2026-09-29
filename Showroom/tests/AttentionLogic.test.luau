--!strict
local AttentionLogic = require("../src/shared/util/AttentionLogic")

return {
    ["applyReact increases"] = function(expect)
        expect(AttentionLogic.applyReact(0)).toEqual(AttentionLogic.reactAmount())
    end,
    ["npcDrip adds over time"] = function(expect)
        local a = AttentionLogic.npcDrip(0, 4, 2)
        expect(a > 0).toBeTruthy()
    end,
}
