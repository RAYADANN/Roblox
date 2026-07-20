--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SessionTypes = require(ReplicatedStorage.shared.types.Session)

export type HudContextValue = {
	hud: SessionTypes.HudPayload,
	toast: string?,
	breedOpen: boolean,
	setBreedOpen: (boolean) -> (),
	selected: { string },
	toggleSelect: (id: string) -> (),
	requestCollect: () -> (),
	requestCreatureRoll: () -> (),
	confirmCreatureBuy: () -> (),
	requestBlockRoll: () -> (),
	confirmBlockBuy: () -> (),
	startBreed: () -> (),
	cancelBreed: () -> (),
	softSpeedBreed: () -> (),
	buildMode: boolean,
	buildBlock: string,
	toggleBuildMode: () -> (),
}

local emptyHud: SessionTypes.HudPayload = {
	cash = 0,
	buffer = 0,
	mps = 0,
	plotId = nil,
	creaturePreview = nil,
	blockPreview = nil,
	incubate = nil,
	lockUntil = 0,
	creatures = {},
	dirt = 0,
	spikes = 0,
	blocks = {},
	notify = nil,
}

local defaultValue: HudContextValue = {
	hud = emptyHud,
	toast = nil,
	breedOpen = false,
	setBreedOpen = function() end,
	selected = {},
	toggleSelect = function() end,
	requestCollect = function() end,
	requestCreatureRoll = function() end,
	confirmCreatureBuy = function() end,
	requestBlockRoll = function() end,
	confirmBlockBuy = function() end,
	startBreed = function() end,
	cancelBreed = function() end,
	softSpeedBreed = function() end,
	buildMode = false,
	buildBlock = "dirt",
	toggleBuildMode = function() end,
}

local HudContext = React.createContext(defaultValue)

return HudContext
