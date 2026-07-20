--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

export type HudContextValue = {
	hud: NetTypes.HudSyncPayload,
	buyUpgrade: (upgradeId: string) -> (),
}

local defaultValue: HudContextValue = {
	hud = { coins = 0, rebirths = 0, upgrades = {} },
	buyUpgrade = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
