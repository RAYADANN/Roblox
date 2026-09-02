--!strict
-- Persisted USP skin equip. Ownership stays server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchManager = require(script.Parent.MatchManager)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local ProfileManager = require(script.Parent.ProfileManager)
local SkinDatabase = require(ReplicatedStorage.shared.data.SkinDatabase)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player, payload: NetTypes.HudSyncPayload?) -> (),
    matchManager: MatchManager.MatchManager,
}

export type SkinManager = {
    setEquippedSkin: (
        self: SkinManager,
        player: Player,
        skinId: string
    ) -> NetTypes.SetEquippedSkinResult,
}

local SkinManager = {}
SkinManager.__index = SkinManager

function SkinManager.new(deps: Deps): SkinManager
    return setmetatable({ _deps = deps }, SkinManager) :: any
end

function SkinManager:setEquippedSkin(player: Player, skinId: string): NetTypes.SetEquippedSkinResult
    if typeof(skinId) ~= "string" then
        return { success = false, error = "bad_value" }
    end

    local resolved = SkinDatabase.resolveId(skinId)
    if not SkinDatabase.isValid(skinId) then
        return { success = false, error = "unknown_skin" }
    end

    local data = self._deps.profileManager:get(player)
    if not data then
        return { success = false, error = "no_profile" }
    end
    if data.ownedSkins[resolved] ~= true then
        return { success = false, error = "skin_not_owned" }
    end

    local ok = self._deps.profileManager:mutate(player, function(profile)
        profile.equippedSkinId = resolved
    end)
    if not ok then
        return { success = false, error = "no_profile" }
    end

    local nextData = self._deps.profileManager:get(player)
    if nextData then
        self._deps.syncHud(player, buildHudPayload.fromPlayerData(nextData))
    end
    self._deps.matchManager:onEquippedSkinChanged(player, resolved)

    return {
        success = true,
        equippedSkinId = resolved,
    }
end

return SkinManager
