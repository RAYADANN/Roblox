--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type FeedEntry = { id: number, text: string, color: Color3 }

export type GiantView = {
    noise: number,
    phase: string,
}

export type HudContextValue = {
    hud: NetTypes.HudSyncPayload,
    giant: GiantView,
    sneaking: boolean,
    carryingItemId: string?,
    feed: { FeedEntry },
    toggleSneak: () -> (),
    drop: () -> (),
}

local defaultValue: HudContextValue = {
    hud = { coins = 0, incomePerSec = 0 },
    giant = { noise = 0, phase = "Deep" },
    sneaking = false,
    carryingItemId = nil,
    feed = {},
    toggleSneak = function() end,
    drop = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
