--!strict
-- Persisted player settings (look sensitivity, crosshair).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrosshairLogic = require(ReplicatedStorage.shared.util.CrosshairLogic)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local ProfileManager = require(script.Parent.ProfileManager)
local SensitivityLogic = require(ReplicatedStorage.shared.util.SensitivityLogic)
local buildHudPayload = require(ReplicatedStorage.shared.util.buildHudPayload)

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player, payload: NetTypes.HudSyncPayload?) -> (),
}

export type SettingsManager = {
    setLookSensitivity: (
        self: SettingsManager,
        player: Player,
        value: number
    ) -> NetTypes.SetSensitivityResult,
    setCrosshair: (
        self: SettingsManager,
        player: Player,
        crosshairId: string
    ) -> NetTypes.SetCrosshairResult,
}

local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new(deps: Deps): SettingsManager
    return setmetatable({ _deps = deps }, SettingsManager) :: any
end

function SettingsManager:setLookSensitivity(
    player: Player,
    value: number
): NetTypes.SetSensitivityResult
    if typeof(value) ~= "number" then
        return { success = false, error = "bad_value" }
    end
    local clamped = SensitivityLogic.clamp(value)
    if not SensitivityLogic.isValid(clamped) then
        return { success = false, error = "out_of_range" }
    end

    local ok = self._deps.profileManager:mutate(player, function(d)
        d.lookSensitivity = clamped
    end)
    if not ok then
        return { success = false, error = "no_profile" }
    end

    local data = self._deps.profileManager:get(player)
    if data then
        self._deps.syncHud(player, buildHudPayload.fromPlayerData(data))
    end

    return { success = true, lookSensitivity = clamped }
end

function SettingsManager:setCrosshair(
    player: Player,
    crosshairId: string
): NetTypes.SetCrosshairResult
    if typeof(crosshairId) ~= "string" then
        return { success = false, error = "bad_value" }
    end
    local resolved = CrosshairLogic.resolve(crosshairId)
    if not CrosshairLogic.isValid(crosshairId) then
        return { success = false, error = "unknown_crosshair" }
    end

    local ok = self._deps.profileManager:mutate(player, function(d)
        d.crosshairId = resolved
    end)
    if not ok then
        return { success = false, error = "no_profile" }
    end

    local data = self._deps.profileManager:get(player)
    if data then
        self._deps.syncHud(player, buildHudPayload.fromPlayerData(data))
    end

    return { success = true, crosshairId = resolved }
end

return SettingsManager
