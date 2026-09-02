local KillFlexLogic = require("@shared/util/KillFlexLogic")

return {
    ["kill flexes victim skin until death"] = function(expect)
        local state = { baseSkinId = "usp_default", flexSkinId = nil }
        expect(KillFlexLogic.visibleSkin(state)).toEqual("usp_default")

        state = KillFlexLogic.onKill(state, "usp_crimson")
        expect(KillFlexLogic.visibleSkin(state)).toEqual("usp_crimson")

        state = KillFlexLogic.onDeath(state)
        expect(KillFlexLogic.visibleSkin(state)).toEqual("usp_default")
        expect(state.flexSkinId == nil).toEqual(true)
    end,
}
