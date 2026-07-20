--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local shared = ReplicatedStorage:WaitForChild("shared")
local Remotes = require(shared.net.Remotes)

local App = require(script.Parent.App)
local HudProvider = require(script.Parent.context.HudProvider)
local HudContext = require(script.Parent.context.HudContext)

type HudState = HudContext.HudState

local function applyLighting(phase: string)
	if phase == "Day" then
		Lighting.ClockTime = 14
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(180, 180, 190)
	elseif phase == "Dusk" then
		Lighting.ClockTime = 18.5
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(120, 90, 70)
	elseif phase == "Night" then
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.4
		Lighting.Ambient = Color3.fromRGB(30, 30, 45)
	else
		Lighting.ClockTime = 6.5
		Lighting.Brightness = 1.4
		Lighting.Ambient = Color3.fromRGB(140, 130, 110)
	end
end

local function nextTutorialStep(step: number, phase: string): number
	if phase == "Dusk" and step <= 3 then
		return 4
	elseif phase == "Dawn" and step == 4 then
		return 0
	end
	return step
end

local CLEAR = {} -- sentinel: patchHud removes this key (Luau drops nil values from tables!)

local function patchHud(prev: HudState, patch: { [string]: any }): HudState
	local nextState = table.clone(prev)
	for key, value in patch do
		if value == CLEAR then
			(nextState :: any)[key] = nil
		else
			(nextState :: any)[key] = value
		end
	end
	return nextState
end

local function GameRoot(): React.ReactElement<any, any>
	local player = Players.LocalPlayer
	local hud, setHud = React.useState({
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
	} :: HudState)

	local phaseEndsAt = React.useRef(os.clock())
	local selectedBlockRef = React.useRef("dirt")
	local rollKindRef = React.useRef("pet" :: string)

	React.useEffect(function()
		applyLighting("Day")
		local conns = {
			Remotes.CycleChanged.OnClientEvent:Connect(function(phase: string, duration: number)
				phaseEndsAt.current = os.clock() + duration
				applyLighting(phase)
				setHud(function(prev)
					local toast = prev.toast
					if phase == "Dusk" then
						toast = "Dusk — prepare flashlight (RMB / F)"
					elseif phase == "Night" then
						toast = ""
					end
					return patchHud(prev, {
						phase = phase,
						remainingSec = duration,
						tutorialStep = nextTutorialStep(prev.tutorialStep, phase),
						toast = toast,
					})
				end)
			end),
			Remotes.Toast.OnClientEvent:Connect(function(message: string)
				setHud(function(prev)
					return patchHud(prev, { toast = message })
				end)
				task.delay(3, function()
					setHud(function(prev)
						if prev.toast == message then
							return patchHud(prev, { toast = "" })
						end
						return prev
					end)
				end)
			end),
			Remotes.InventorySync.OnClientEvent:Connect(function(inventory: any)
				if typeof(inventory) ~= "table" then
					return
				end
				setHud(function(prev)
					return patchHud(prev, { inventory = inventory, selectedInvIndex = CLEAR })
				end)
			end),
			Remotes.BlockInvSync.OnClientEvent:Connect(function(blockInv: any)
				if typeof(blockInv) ~= "table" then
					return
				end
				setHud(function(prev)
					return patchHud(prev, { blockInv = blockInv })
				end)
			end),
			Remotes.RollResult.OnClientEvent:Connect(function(payload: any)
				if typeof(payload) ~= "table" then
					return
				end
				local id = payload.id or payload.petId
				if payload.cleared == true or id == "" or id == nil then
					setHud(function(prev)
						return patchHud(prev, { rollOffer = CLEAR })
					end)
					return
				end
				local kind = if payload.kind == "block" then "block" else "pet"
				rollKindRef.current = kind
				player:SetAttribute("ClientBuildMode", false)
				setHud(function(prev)
					return patchHud(prev, {
						buildOpen = false,
						rollOffer = {
							kind = kind,
							id = id,
							displayName = payload.displayName or id,
							rarity = payload.rarity or "Common",
							oneIn = payload.oneIn or 2,
							buyCost = payload.buyCost or 0,
							grantQty = payload.grantQty,
							spinCost = payload.spinCost or 0,
							animating = payload.animating == true,
						},
						tutorialStep = if prev.tutorialStep == 1 then 2 else prev.tutorialStep,
					})
				end)
			end),
			Remotes.OpenBuild.OnClientEvent:Connect(function()
				setHud(function(prev)
					return patchHud(prev, {
						buildOpen = true,
						tutorialStep = if prev.tutorialStep == 1 then 2 else prev.tutorialStep,
					})
				end)
				player:SetAttribute("ClientBuildMode", true)
			end),
			Remotes.PlotStateSync.OnClientEvent:Connect(function(payload: any)
				if typeof(payload) ~= "table" then
					return
				end
				setHud(function(prev)
					return patchHud(prev, { locked = payload.locked == true })
				end)
			end),
		}

		local running = true
		task.spawn(function()
			while running do
				task.wait(0.2)
				local credits = player:GetAttribute("Credits")
				local income = player:GetAttribute("IncomePerSec")
				local buffer = player:GetAttribute("Buffer")
				local battery = player:GetAttribute("Battery")
				local fog = player:GetAttribute("FogPetId")
				setHud(function(prev)
					return patchHud(prev, {
						credits = if typeof(credits) == "number" then credits else prev.credits,
						incomePerSec = if typeof(income) == "number" then income else prev.incomePerSec,
						buffer = if typeof(buffer) == "number" then buffer else prev.buffer,
						battery = if typeof(battery) == "number" then battery else prev.battery,
						fogPetId = if typeof(fog) == "string" and fog ~= "" then fog else "",
						remainingSec = math.max(0, phaseEndsAt.current - os.clock()),
					})
				end)
			end
		end)

		task.delay(10, function()
			setHud(function(prev)
				if prev.tutorialStep == 1 then
					return patchHud(prev, { tutorialStep = 2 })
				end
				return prev
			end)
		end)
		task.delay(22, function()
			setHud(function(prev)
				if prev.tutorialStep == 2 then
					return patchHud(prev, { tutorialStep = 3 })
				end
				return prev
			end)
		end)

		return function()
			running = false
			for _, conn in conns do
				conn:Disconnect()
			end
		end
	end, {})

	local reclaimFog = React.useCallback(function()
		Remotes.ReclaimFog:FireServer()
	end, {})
	local toggleLock = React.useCallback(function()
		Remotes.ToggleLock:FireServer()
	end, {})
	local selectInv = React.useCallback(function(index: number)
		setHud(function(prev)
			return patchHud(prev, { selectedInvIndex = index })
		end)
	end, {})
	local releaseSelected = React.useCallback(function()
		setHud(function(prev)
			if prev.selectedInvIndex then
				Remotes.PlacePet:FireServer(prev.selectedInvIndex)
			end
			return prev
		end)
	end, {})
	local selectBlock = React.useCallback(function(blockId: string)
		selectedBlockRef.current = blockId
		setHud(function(prev)
			return patchHud(prev, { selectedBlockId = blockId, buildOpen = true })
		end)
		player:SetAttribute("ClientBuildMode", true)
		player:SetAttribute("SelectedBlockId", blockId)
	end, {})
	local openBuild = React.useCallback(function()
		setHud(function(prev)
			return patchHud(prev, { buildOpen = true })
		end)
		player:SetAttribute("ClientBuildMode", true)
	end, {})
	local closeBuild = React.useCallback(function()
		setHud(function(prev)
			return patchHud(prev, { buildOpen = false })
		end)
		player:SetAttribute("ClientBuildMode", false)
	end, {})
	local collectAll = React.useCallback(function()
		Remotes.CollectAll:FireServer()
	end, {})
	local buyRolledPet = React.useCallback(function()
		Remotes.ConfirmBuy:FireServer(rollKindRef.current)
		setHud(function(prev)
			return patchHud(prev, { rollOffer = CLEAR })
		end)
	end, {})
	local spinAgain = React.useCallback(function()
		Remotes.RequestRoll:FireServer(rollKindRef.current)
	end, {})
	local closeRoll = React.useCallback(function()
		setHud(function(prev)
			return patchHud(prev, { rollOffer = CLEAR })
		end)
	end, {})

	local value = React.useMemo(function()
		return {
			hud = hud,
			reclaimFog = reclaimFog,
			toggleLock = toggleLock,
			collectAll = collectAll,
			selectInv = selectInv,
			releaseSelected = releaseSelected,
			selectBlock = selectBlock,
			openBuild = openBuild,
			closeBuild = closeBuild,
			buyRolledPet = buyRolledPet,
			confirmBuy = buyRolledPet,
			spinAgain = spinAgain,
			closeRoll = closeRoll,
		}
	end, {
		hud,
		reclaimFog,
		toggleLock,
		collectAll,
		selectInv,
		releaseSelected,
		selectBlock,
		openBuild,
		closeBuild,
		buyRolledPet,
		spinAgain,
		closeRoll,
	} :: { any })

	return React.createElement(HudProvider, { value = value }, {
		App = React.createElement(App),
	})
end

return GameRoot
