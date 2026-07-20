--!strict

--[[
	Plot = Hub (wood, +Z) + Yard (grass grid).
	Dual roll pads + Collect on Hub. Build/pets on Yard.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local BlockDatabase = require(shared.data.BlockDatabase)
local Config = BlockDatabase.Config

export type BasePlot = {
	index: number,
	model: Model,
	origin: CFrame, -- yard origin
	hubOrigin: CFrame,
	yardFloor: BasePart,
	hubFloor: BasePart,
	blockRollPad: BasePart,
	petRollPad: BasePart,
	collectButton: BasePart,
	lockPad: BasePart,
	spawnCFrame: CFrame,
	monsterSpawn: Vector3,
	fogCage: BasePart,
	ownerUserId: number?,
	lockedUntil: number,
	blockCount: number,
	grid: { [string]: BasePart },
	destroy: (self: BasePlot) -> (),
}

local BaseBuilder = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(60, 60, 70)
	p.Size = props.Size
	p.CFrame = props.CFrame
	p.Name = props.Name or "Part"
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	p.Parent = props.Parent
	return p
end

local function billboard(parent: BasePart, text: string, offsetY: number?): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 48)
	gui.StudsOffset = Vector3.new(0, offsetY or 3.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
	return gui
end

local function makeRollPad(
	parent: Model,
	hubCf: CFrame,
	localPos: Vector3,
	name: string,
	title: string
): BasePart
	local pad = part({
		Name = name,
		Size = Vector3.new(5, 0.4, 5),
		CFrame = hubCf * CFrame.new(localPos),
		Color = Color3.fromRGB(180, 40, 40),
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	})
	-- yellow rim
	part({
		Name = name .. "_Rim",
		Size = Vector3.new(5.4, 0.15, 5.4),
		CFrame = hubCf * CFrame.new(localPos + Vector3.new(0, -0.2, 0)),
		Color = Color3.fromRGB(255, 210, 60),
		CanCollide = false,
		Parent = parent,
	})
	local preview = part({
		Name = name .. "_Preview",
		Size = Vector3.new(2.2, 2.2, 2.2),
		CFrame = hubCf * CFrame.new(localPos + Vector3.new(0, 2.2, 0)),
		Color = Color3.fromRGB(20, 20, 28),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	preview:SetAttribute("IsPreview", true)
	billboard(pad, title, 5)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Roll"
	prompt.ObjectText = title
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	return pad
end

function BaseBuilder.createPlot(origin: CFrame, plotIndex: number, parent: Instance?): BasePlot
	local model = Instance.new("Model")
	model.Name = "Plot_" .. plotIndex
	model:SetAttribute("PlotIndex", plotIndex)
	model.Parent = parent or Workspace

	local yardSize = Config.YARD_SIZE
	local hubDepth = Config.HUB_DEPTH
	local hubWidth = Config.HUB_WIDTH

	-- Yard grass (center at origin)
	local yardFloor = part({
		Name = "YardFloor",
		Size = Vector3.new(yardSize, 1, yardSize),
		CFrame = origin * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(55, 120, 55),
		Material = Enum.Material.Grass,
		Parent = model,
	})

	-- Grid cells on yard
	local gridFolder = Instance.new("Folder")
	gridFolder.Name = "BuildGrid"
	gridFolder.Parent = model
	for cx = Config.GRID_MIN, Config.GRID_MAX do
		for cz = Config.GRID_MIN, Config.GRID_MAX do
			local localPos = Config.cellToLocal(cx, 0, cz)
			local shade = ((cx + cz) % 2 == 0)
			part({
				Name = string.format("Grid_%d_%d", cx, cz),
				Size = Vector3.new(Config.CELL_SIZE - 0.2, 0.06, Config.CELL_SIZE - 0.2),
				CFrame = origin * CFrame.new(localPos.X, 1.06, localPos.Z),
				Color = if shade then Color3.fromRGB(45, 100, 45) else Color3.fromRGB(65, 130, 65),
				CanCollide = false,
				Transparency = 0.15,
				Parent = gridFolder,
			})
		end
	end

	-- Hub wood: attached at +Z of yard (facade side)
	local hubCenterLocal = Vector3.new(0, 0, yardSize * 0.5 + hubDepth * 0.5)
	local hubOrigin = origin * CFrame.new(hubCenterLocal)
	local hubFloor = part({
		Name = "HubFloor",
		Size = Vector3.new(hubWidth, 1, hubDepth),
		CFrame = hubOrigin * CFrame.new(0, 0.5, 0),
		Color = Color3.fromRGB(120, 85, 50),
		Material = Enum.Material.WoodPlanks,
		Parent = model,
	})

	local blockRollPad = makeRollPad(model, hubOrigin, Vector3.new(-6, 1.2, -2), "BlockRollPad", "Block Roll")
	local petRollPad = makeRollPad(model, hubOrigin, Vector3.new(6, 1.2, -2), "PetRollPad", "Pet Roll")

	local collectButton = part({
		Name = "CollectButton",
		Size = Vector3.new(6, 1.2, 3),
		CFrame = hubOrigin * CFrame.new(0, 1.1, 6),
		Color = Color3.fromRGB(40, 180, 80),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	billboard(collectButton, "Collect All", 2.5)
	local collectPrompt = Instance.new("ProximityPrompt")
	collectPrompt.ActionText = "Collect"
	collectPrompt.ObjectText = "Cash buffer"
	collectPrompt.HoldDuration = 0.15
	collectPrompt.MaxActivationDistance = 14
	collectPrompt.RequiresLineOfSight = false
	collectPrompt.Parent = collectButton

	local lockPad = part({
		Name = "LockPad",
		Size = Vector3.new(4, 1, 4),
		CFrame = hubOrigin * CFrame.new(10, 1, 6),
		Color = Color3.fromRGB(70, 70, 90),
		Parent = model,
	})
	billboard(lockPad, "Base Lock FREE", 2.2)
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.ActionText = "Lock"
	lockPrompt.ObjectText = "Base"
	lockPrompt.HoldDuration = 0.15
	lockPrompt.MaxActivationDistance = 10
	lockPrompt.RequiresLineOfSight = false
	lockPrompt.Parent = lockPad

	local fogCage = part({
		Name = "FogCage",
		Size = Vector3.new(6, 6, 6),
		CFrame = hubOrigin * CFrame.new(0, 3, hubDepth * 0.5 + 10),
		Color = Color3.fromRGB(40, 20, 60),
		Transparency = 0.35,
		CanCollide = false,
		Parent = model,
	})

	return {
		index = plotIndex,
		model = model,
		origin = origin,
		hubOrigin = hubOrigin,
		yardFloor = yardFloor,
		hubFloor = hubFloor,
		blockRollPad = blockRollPad,
		petRollPad = petRollPad,
		collectButton = collectButton,
		lockPad = lockPad,
		spawnCFrame = hubOrigin * CFrame.new(0, 3, 0),
		monsterSpawn = (hubOrigin * CFrame.new(0, 3, hubDepth * 0.5 + 6)).Position,
		fogCage = fogCage,
		ownerUserId = nil,
		lockedUntil = 0,
		blockCount = 0,
		grid = {},
		destroy = function(self)
			self.model:Destroy()
		end,
	}
end

-- Legacy stub: no shared hub machine
function BaseBuilder.createHub(parent: Instance?): (Model, BasePart)
	local model = Instance.new("Model")
	model.Name = "Hub"
	model.Parent = parent or Workspace
	local dummy = part({
		Name = "LegacyHubMarker",
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(0, -50, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})
	return model, dummy
end

return BaseBuilder
