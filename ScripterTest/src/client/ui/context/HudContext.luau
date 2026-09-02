--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)

export type HudContextValue = {
	hud: NetTypes.HudSyncPayload,
	achievementsOpen: boolean,
	setAchievementsOpen: (open: boolean) -> (),
}

local defaultValue: HudContextValue = {
	hud = NetTypes.emptyHud(),
	achievementsOpen = false,
	setAchievementsOpen = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
