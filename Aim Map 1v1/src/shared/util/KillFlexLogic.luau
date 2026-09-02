--!strict
-- Temporary USP skin on kill until the killer dies. Shop owns permanent skins.

export type FlexState = {
    baseSkinId: string,
    flexSkinId: string?,
}

local KillFlexLogic = {}

function KillFlexLogic.visibleSkin(state: FlexState): string
    return state.flexSkinId or state.baseSkinId
end

function KillFlexLogic.onKill(state: FlexState, victimSkinId: string): FlexState
    return {
        baseSkinId = state.baseSkinId,
        flexSkinId = victimSkinId,
    }
end

function KillFlexLogic.onDeath(state: FlexState): FlexState
    return {
        baseSkinId = state.baseSkinId,
        flexSkinId = nil,
    }
end

return KillFlexLogic
