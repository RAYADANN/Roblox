--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local HudContext = require(script.Parent.HudContext)
local SessionTypes = require(ReplicatedStorage.shared.types.Session)
local Toast = require(script.Parent.Parent.components.Toast)

export type Props = {
	children: any,
	hud: SessionTypes.HudPayload,
	toast: string?,
	toastTone: Toast.Tone,
	carryStatus: string?,
	carryStartedAt: number?,
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

local function HudProvider(props: Props): React.Node
	local value: HudContext.HudContextValue = {
		hud = props.hud,
		toast = props.toast,
		toastTone = props.toastTone,
		carryStatus = props.carryStatus,
		carryStartedAt = props.carryStartedAt,
		breedOpen = props.breedOpen,
		setBreedOpen = props.setBreedOpen,
		selected = props.selected,
		toggleSelect = props.toggleSelect,
		requestCollect = props.requestCollect,
		requestCreatureRoll = props.requestCreatureRoll,
		confirmCreatureBuy = props.confirmCreatureBuy,
		requestBlockRoll = props.requestBlockRoll,
		confirmBlockBuy = props.confirmBlockBuy,
		startBreed = props.startBreed,
		cancelBreed = props.cancelBreed,
		softSpeedBreed = props.softSpeedBreed,
		buildMode = props.buildMode,
		buildBlock = props.buildBlock,
		toggleBuildMode = props.toggleBuildMode,
	}

	return React.createElement(HudContext.Provider, {
		value = value,
	}, props.children)
end

return HudProvider
