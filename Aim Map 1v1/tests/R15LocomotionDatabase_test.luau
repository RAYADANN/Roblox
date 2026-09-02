local R15LocomotionDatabase = require("@shared/data/R15LocomotionDatabase")

return {
    ["idle and walk are rbxassetid"] = function(expect)
        expect(string.sub(R15LocomotionDatabase.IDLE, 1, 13)).toEqual("rbxassetid://")
        expect(string.sub(R15LocomotionDatabase.WALK, 1, 13)).toEqual("rbxassetid://")
        expect(R15LocomotionDatabase.IDLE ~= R15LocomotionDatabase.WALK).toEqual(true)
    end,
}
