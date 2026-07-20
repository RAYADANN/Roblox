--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type RollOffer = {
	kind: "block" | "pet",
	id: string,
	displayName: string,
	rarity: string,
	oneIn: number,
	buyCost: number,
	grantQty: number?,
	spinCost: number,
	animating: boolean,
	cleared: boolean?,
}

export type HudState = {
	credits: number,
	incomePerSec: number,
	buffer: number,
	battery: number,
	phase: string,
	remainingSec: number,
	toast: string,
	fogPetId: string,
	tutorialStep: number,
	inventory: { string },
	blockInv: { [string]: number },
	selectedInvIndex: number?,
	buildOpen: boolean,
	selectedBlockId: string?,
	locked: boolean,
	rollOffer: RollOffer?,
}

export type HudContextValue = {
	hud: HudState,
	reclaimFog: () -> (),
	toggleLock: () -> (),
	collectAll: () -> (),
	selectInv: (index: number) -> (),
	releaseSelected: () -> (),
	selectBlock: (blockId: string) -> (),
	openBuild: () -> (),
	closeBuild: () -> (),
	buyRolledPet: () -> (),
	confirmBuy: () -> (),
	spinAgain: () -> (),
	closeRoll: () -> (),
}

local default: HudContextValue = {
	hud = {
		credits = 0,
		incomePerSec = 0,
		buffer = 0,
		battery = 1,
		phase = "Day",
		remainingSec = 0,
		toast = "",
		fogPetId = "",
		tutorialStep = 1,
		inventory = {},
		blockInv = {},
		selectedInvIndex = nil,
		buildOpen = false,
		selectedBlockId = "dirt",
		locked = false,
		rollOffer = nil,
	},
	reclaimFog = function() end,
	toggleLock = function() end,
	collectAll = function() end,
	selectInv = function() end,
	releaseSelected = function() end,
	selectBlock = function() end,
	openBuild = function() end,
	closeBuild = function() end,
	buyRolledPet = function() end,
	confirmBuy = function() end,
	spinAgain = function() end,
	closeRoll = function() end,
}

return React.createContext(default)
