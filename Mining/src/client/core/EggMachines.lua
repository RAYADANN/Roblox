--!strict
-- Машины яиц в Workspace.Eggs: ProximityPrompt + ClickDetector → EggShopModal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage:WaitForChild("shared").constants)
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t
local Formatters = require(script.Parent.Parent.ui.hud.formatters)
local SoundManager = require(script.Parent.SoundManager)
local EggShopModal = require(script.Parent.Parent.ui.EggShopModal)

local EggMachines = {}

export type InitOptions = {
	getCoins: (() -> number)?,
}

type WiredMachine = {
	model: Model,
	eggId: string?,
	eggDef: any?,
	host: BasePart,
	clickConns: { RBXScriptConnection },
	promptConns: { RBXScriptConnection },
}

local PROMPT_MAX_DIST = 22
local CLICK_MAX_DIST = 40

local PROMPT_NAME = "DeepDigger_EggPrompt"
local CLICK_DETECTOR_NAME = "DeepDigger_EggClick"

local _machines: { WiredMachine } = {}
local _openedEggId: string? = nil
local _initialized = false

local EGG_ID_BY_MODEL: { [string]: string } = {
	Basic = "basic",
	Desert = "desert",
	Mine = "mine",
	Candy = "candy",
	Ocean = "ocean",
	Lava = "lava",
	["Explosive Hydro"] = "explosive_hydro",
}

local _getCoins: () -> number = function()
	return 0
end

local function eggDefForModel(modelName: string): any?
	local eggId = EGG_ID_BY_MODEL[modelName]
	if not eggId then
		return nil
	end
	local eggs = (Constants.PETS or {}).eggs or {}
	return eggs[eggId]
end

local function findClickPart(machine: Model): BasePart?
	local best: BasePart? = nil
	local bestVolume = 0
	for _, desc in machine:GetDescendants() do
		if desc:IsA("BasePart") and desc.Transparency < 0.95 then
			local s = desc.Size
			local vol = s.X * s.Y * s.Z
			if vol > bestVolume then
				bestVolume = vol
				best = desc
			end
		end
	end
	if best then
		return best
	end
	return findPromptHost(machine)
end

local function findPromptHost(machine: Model): BasePart?
	local key = machine:FindFirstChild("Key", true)
	if key and key:IsA("BasePart") then
		return key
	end
	local primary = machine.PrimaryPart
	if primary then
		return primary
	end
	return machine:FindFirstChildWhichIsA("BasePart", true)
end

local function waitForHost(machine: Model, timeoutSec: number): BasePart?
	local deadline = os.clock() + timeoutSec
	while os.clock() < deadline do
		local host = findPromptHost(machine)
		if host then
			return host
		end
		if not machine.Parent then
			return nil
		end
		task.wait(0.2)
	end
	return findPromptHost(machine)
end

local function updateBillboards(machine: Model, eggDef: any?)
	local nameText = if eggDef then eggDef.name else machine.Name
	local priceText = if eggDef and eggDef.cost
		then L("world.egg.priceCoins", { amount = Formatters.shortNumber(eggDef.cost) })
		else L("world.egg.soon")
	for _, gui in ipairs(machine:GetDescendants()) do
		if gui:IsA("BillboardGui") then
			local nameLabel = gui:FindFirstChild("NameLabel", true)
			if nameLabel and nameLabel:IsA("TextLabel") then
				nameLabel.Text = nameText
			end
			local priceLabel = gui:FindFirstChild("PriceLabel", true)
			if priceLabel and priceLabel:IsA("TextLabel") then
				priceLabel.Text = priceText
			end
		end
	end
end

local function updatePrompt(entry: WiredMachine)
	local prompt = entry.host:FindFirstChild(PROMPT_NAME)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end
	if entry.eggDef then
		prompt.ObjectText = entry.eggDef.name or entry.model.Name
		prompt.ActionText = L("world.egg.open")
		prompt.Enabled = true
	else
		prompt.ObjectText = entry.model.Name
		prompt.ActionText = L("world.egg.soon")
		prompt.Enabled = false
	end
end

local function openShop(eggId: string, eggDef: any, playClickSound: boolean?)
	if playClickSound ~= false then
		SoundManager.play("ui_click")
	end
	_openedEggId = eggId
	EggShopModal.show({
		eggId = eggId,
		eggDef = eggDef,
		getCoins = _getCoins,
		onClose = function()
			_openedEggId = nil
		end,
	})
end

local function openShopFromInteraction(eggId: string, eggDef: any, playClickSound: boolean?)
	if EggShopModal.isOpenForEgg(eggId) then
		_openedEggId = eggId
		return
	end
	local ok, err = pcall(function()
		openShop(eggId, eggDef, playClickSound)
	end)
	if not ok then
		warn("[EggMachines] не удалось открыть магазин яйца:", err)
		_openedEggId = nil
	end
end

local function onPromptHidden(eggId: string)
	if _openedEggId == eggId and EggShopModal.isOpenForEgg(eggId) then
		EggShopModal.close()
	end
end

local function disconnectConns(conns: { RBXScriptConnection })
	for _, conn in ipairs(conns) do
		conn:Disconnect()
	end
	table.clear(conns)
end

local function wireClickDetectors(entry: WiredMachine)
	if not entry.eggId or not entry.eggDef then
		return
	end

	disconnectConns(entry.clickConns)

	local clickPart = findClickPart(entry.model) or entry.host
	local detector = clickPart:FindFirstChild(CLICK_DETECTOR_NAME)
	if not detector then
		detector = Instance.new("ClickDetector")
		detector.Name = CLICK_DETECTOR_NAME
		detector.Parent = clickPart
	end
	if detector:IsA("ClickDetector") then
		detector.MaxActivationDistance = CLICK_MAX_DIST
	end

	local eggId = entry.eggId
	local eggDef = entry.eggDef
	table.insert(entry.clickConns, detector.MouseClick:Connect(function()
		openShopFromInteraction(eggId, eggDef, true)
	end))
end

local function wireProximityPrompt(entry: WiredMachine)
	disconnectConns(entry.promptConns)

	local host = entry.host
	local prompt = host:FindFirstChild(PROMPT_NAME)
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = PROMPT_NAME
		prompt.MaxActivationDistance = PROMPT_MAX_DIST
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = host
	elseif not prompt:IsA("ProximityPrompt") then
		prompt:Destroy()
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = PROMPT_NAME
		prompt.MaxActivationDistance = PROMPT_MAX_DIST
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = host
	end

	updatePrompt(entry)

	if not entry.eggId or not entry.eggDef then
		return
	end

	local eggId = entry.eggId
	local eggDef = entry.eggDef
	table.insert(entry.promptConns, prompt.Triggered:Connect(function()
		openShopFromInteraction(eggId, eggDef, true)
	end))
	table.insert(entry.promptConns, prompt.PromptHidden:Connect(function()
		onPromptHidden(eggId)
	end))
end

local function registerMachine(machine: Model, host: BasePart, eggDef: any?)
	for _, entry in ipairs(_machines) do
		if entry.model == machine then
			return
		end
	end

	table.insert(_machines, {
		model = machine,
		eggId = eggDef and eggDef.id,
		eggDef = eggDef,
		host = host,
		clickConns = {},
		promptConns = {},
	})

	local entry = _machines[#_machines]
	wireProximityPrompt(entry)
	wireClickDetectors(entry)

	machine:SetAttribute("DeepDigger_EggWired", true)
end

local function wireMachine(machine: Model)
	for _, entry in ipairs(_machines) do
		if entry.model == machine then
			return
		end
	end

	local eggDef = eggDefForModel(machine.Name)
	updateBillboards(machine, eggDef)

	local host = findPromptHost(machine)
	if host then
		registerMachine(machine, host, eggDef)
		return
	end

	task.spawn(function()
		local resolvedHost = waitForHost(machine, 45)
		if not resolvedHost then
			warn("[EggMachines] нет host-части у", machine:GetFullName())
			return
		end
		updateBillboards(machine, eggDef)
		registerMachine(machine, resolvedHost, eggDef)
	end)
end

local function refreshMachines()
	local folder = Workspace:FindFirstChild("Eggs")
	if not folder or not folder:IsA("Folder") then
		return
	end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			wireMachine(child)
		end
	end
end

local function startLateWireRetry()
	task.spawn(function()
		for _ = 1, 60 do
			refreshMachines()
			task.wait(1)
		end
	end)
end

function EggMachines.init(opts: InitOptions?)
	if opts and opts.getCoins then
		_getCoins = opts.getCoins
	end

	refreshMachines()

	if not _initialized then
		_initialized = true
		local folder = Workspace:FindFirstChild("Eggs")
		if folder and folder:IsA("Folder") then
			folder.ChildAdded:Connect(function(child)
				if child:IsA("Model") then
					task.defer(function()
						wireMachine(child)
					end)
				end
			end)
		end
		startLateWireRetry()
	end
end

return EggMachines
