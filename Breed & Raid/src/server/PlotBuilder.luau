--!strict

-- Procedural Hub+Yard graybox per GDD §3.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotConfig = require(ReplicatedStorage.shared.data.PlotConfig)
local WorldUi = require(ReplicatedStorage.shared.ui.WorldUi)

export type PlotModel = {
	id: number,
	model: Model,
	origin: Vector3,
	hubCenter: Vector3,
	spawnCFrame: CFrame,
	nests: { [string]: BasePart },
	collectPart: BasePart,
	creatureRollPart: BasePart,
	blockRollPart: BasePart,
	lockPart: BasePart,
	incubatorPart: BasePart,
	buildFolder: Folder,
	petZone: Folder,
	yardFloor: BasePart,
	ownerUserId: number?,
}

local PlotBuilder = {}

local function part(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	anchored: boolean?,
	parent: Instance,
	canCollide: boolean?,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color
	p.Material = props.material or Enum.Material.Plastic
	p.Anchored = if props.anchored == nil then true else props.anchored
	p.CanCollide = if props.canCollide == nil then true else props.canCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = props.parent
	return p
end

function PlotBuilder.applyLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(118, 112, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(145, 140, 128)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 230)
	Lighting.ColorShift_Bottom = Color3.fromRGB(180, 190, 170)
end

function PlotBuilder.originForIndex(index: number, count: number): Vector3
	local hub = PlotConfig.hubSize
	local yard = PlotConfig.yardSize
	local footprintZ = yard.Y + PlotConfig.junctionDepth + hub.Y
	local footprintX = math.max(hub.X, yard.X)
	local spacing = math.max(footprintX, footprintZ) + PlotConfig.plotGap
	local angle = ((index - 1) / count) * math.pi * 2
	local radius = spacing
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function buildNest(parent: Instance, nestId: string, yardOrigin: Vector3): BasePart
	local offset = PlotConfig.nestOffsets[nestId]
	local height = PlotConfig.nestPedestalHeight
	local pos = yardOrigin + Vector3.new(offset.X, height / 2, offset.Y)
	local pedestal = part({
		name = nestId,
		size = Vector3.new(4, height, 4),
		cframe = CFrame.new(pos),
		color = Color3.fromRGB(210, 198, 175),
		material = Enum.Material.SmoothPlastic,
		parent = parent,
	})
	pedestal:SetAttribute("NestId", nestId)
	return pedestal
end

function PlotBuilder.buildPlot(id: number, origin: Vector3, parent: Instance): PlotModel
	local model = Instance.new("Model")
	model.Name = `Plot{id}`
	model:SetAttribute("PlotId", id)
	model.Parent = parent

	local yard = PlotConfig.yardSize
	local hub = PlotConfig.hubSize
	local junction = PlotConfig.junctionDepth

	local yardCenter = origin
	local yardFloorY = 0
	local yardFloor = part({
		name = "YardFloor",
		size = Vector3.new(yard.X, 1, yard.Y),
		cframe = CFrame.new(yardCenter + Vector3.new(0, yardFloorY - 0.5, 0)),
		color = Color3.fromRGB(70, 140, 60),
		material = Enum.Material.Grass,
		parent = model,
	})
	yardFloor:SetAttribute("IsYard", true)
	yardFloor:SetAttribute("PlotId", id)

	local hubCenterZ = yard.Y / 2 + junction + hub.Y / 2
	local hubCenter = origin + Vector3.new(0, 0, hubCenterZ)
	part({
		name = "HubFloor",
		size = Vector3.new(hub.X, 1, hub.Y),
		cframe = CFrame.new(hubCenter + Vector3.new(0, yardFloorY - 0.5, 0)),
		color = Color3.fromRGB(140, 100, 60),
		material = Enum.Material.WoodPlanks,
		parent = model,
	})

	part({
		name = "Junction",
		size = Vector3.new(math.min(hub.X, 16), 1, junction),
		cframe = CFrame.new(origin + Vector3.new(0, yardFloorY - 0.5, yard.Y / 2 + junction / 2)),
		color = Color3.fromRGB(110, 90, 55),
		material = Enum.Material.WoodPlanks,
		parent = model,
	})

	local nestsFolder = Instance.new("Folder")
	nestsFolder.Name = "Nests"
	nestsFolder.Parent = model

	local nests: { [string]: BasePart } = {}
	for nestId in PlotConfig.nestOffsets do
		nests[nestId] = buildNest(nestsFolder, nestId, yardCenter)
		local unlocked = nestId == "N1" or nestId == "N2" or nestId == "N3" or nestId == "N4"
		nests[nestId]:SetAttribute("Unlocked", unlocked)
		WorldUi.styleNest(nests[nestId], unlocked, false)
	end

	local pads = Instance.new("Folder")
	pads.Name = "HubPads"
	pads.Parent = model

	local function hubPad(name: string, localOffset: Vector3, kind: "creature" | "block" | "collect" | "lock" | "incubator" | "spawn"): BasePart
		local p = part({
			name = name,
			size = Vector3.new(4.2, 0.35, 4.2),
			cframe = CFrame.new(hubCenter + localOffset + Vector3.new(0, 0.18, 0)),
			color = Color3.fromRGB(200, 190, 170),
			material = Enum.Material.SmoothPlastic,
			parent = pads,
		})
		WorldUi.styleHubPad(p, kind)
		return p
	end

	local function makePrompt(
		parent: Instance,
		name: string,
		action: string,
		object: string,
		hold: number,
		dist: number,
		kind: string
	): ProximityPrompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = name
		prompt.ActionText = action
		prompt.ObjectText = object
		prompt.HoldDuration = hold
		prompt.MaxActivationDistance = dist
		prompt.Parent = parent
		WorldUi.stylePrompt(prompt, kind)
		return prompt
	end

	local spawnPart = hubPad("Spawn", PlotConfig.hubObjects.spawn, "spawn")
	local creatureRollPart = hubPad("CreatureRoll", PlotConfig.hubObjects.creatureRoll, "creature")
	local blockRollPart = hubPad("BlockRoll", PlotConfig.hubObjects.blockRoll, "block")
	local collectPart = hubPad("Collect", PlotConfig.hubObjects.collect, "collect")
	local lockPart = hubPad("Lock", PlotConfig.hubObjects.lockPad, "lock")
	local incubatorPart = hubPad("Incubator", PlotConfig.hubObjects.incubator, "incubator")

	makePrompt(collectPart, "CollectPrompt", "Collect All", "Cash ready", 0, 12, "collect")
	makePrompt(creatureRollPart, "CreatureRollPrompt", "Roll Creature", "Free preview", 0, 12, "roll")
	makePrompt(creatureRollPart, "CreatureBuyPrompt", "Buy Creature", "Confirm purchase", 0, 12, "buy").Enabled = false
	makePrompt(blockRollPart, "BlockRollPrompt", "Roll Blocks", "Free preview", 0, 12, "roll")
	makePrompt(blockRollPart, "BlockBuyPrompt", "Buy Pack", "+100 blocks", 0, 12, "buy").Enabled = false
	makePrompt(lockPart, "LockPrompt", "Lock Base", "45 seconds", 0, 12, "lock")
	makePrompt(incubatorPart, "IncubatorPrompt", "Open Breed", "Fuse two pets", 0, 12, "breed")

	WorldUi.attachPadPreview(creatureRollPart, "CreaturePreviewBillboard", "CREATURE ROLL")
	WorldUi.attachPadPreview(blockRollPart, "BlockPreviewBillboard", "BLOCK ROLL")

	local egg = part({
		name = "Egg",
		size = Vector3.new(2, 2.5, 2),
		cframe = CFrame.new(incubatorPart.Position + Vector3.new(0, 2, 0)),
		color = Color3.fromRGB(245, 232, 210),
		material = Enum.Material.SmoothPlastic,
		parent = incubatorPart,
		canCollide = false,
	})
	egg.Transparency = 0.2

	WorldUi.attachStatusBillboard(incubatorPart, "IncubateBillboard", {
		size = UDim2.fromOffset(150, 52),
		offset = Vector3.new(0, 4.2, 0),
		labelName = "TimerLabel",
		defaultText = "Ready",
		accent = Color3.fromRGB(150, 120, 180),
	})

	WorldUi.attachStatusBillboard(collectPart, "BufferBillboard", {
		size = UDim2.fromOffset(140, 52),
		offset = Vector3.new(0, 3.4, 0),
		labelName = "BufferLabel",
		defaultText = "$0",
		accent = WorldUi.Colors.jade,
	})

	local buildFolder = Instance.new("Folder")
	buildFolder.Name = "Build"
	buildFolder.Parent = model

	local petZone = Instance.new("Folder")
	petZone.Name = "PetZone"
	petZone.Parent = model

	local zoneMark = part({
		name = "PetZoneMark",
		size = Vector3.new(yard.X - PlotConfig.petZoneMargin * 2, 0.12, yard.Y - PlotConfig.petZoneMargin * 2),
		cframe = CFrame.new(yardCenter + Vector3.new(0, 0.06, 0)),
		color = Color3.fromRGB(111, 168, 138),
		material = Enum.Material.SmoothPlastic,
		parent = petZone,
		canCollide = false,
	})
	zoneMark.Transparency = 0.88

	return {
		id = id,
		model = model,
		origin = origin,
		hubCenter = hubCenter,
		spawnCFrame = spawnPart.CFrame + Vector3.new(0, 3, 0),
		nests = nests,
		collectPart = collectPart,
		creatureRollPart = creatureRollPart,
		blockRollPart = blockRollPart,
		lockPart = lockPart,
		incubatorPart = incubatorPart,
		buildFolder = buildFolder,
		petZone = petZone,
		yardFloor = yardFloor,
		ownerUserId = nil,
	}
end

function PlotBuilder.buildWorld(plotCount: number): { PlotModel }
	PlotBuilder.applyLighting()

	local folder = Workspace:FindFirstChild("Plots")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = Workspace

	local plots: { PlotModel } = {}
	for i = 1, plotCount do
		local origin = PlotBuilder.originForIndex(i, plotCount)
		plots[i] = PlotBuilder.buildPlot(i, origin, folder)

		if i > 1 then
			local a = plots[i - 1].origin
			local b = plots[i].origin
			local mid = (a + b) / 2
			local dir = (b - a)
			local dist = dir.Magnitude
			if dist > 0 then
				part({
					name = `RaidPath_{i - 1}_{i}`,
					size = Vector3.new(PlotConfig.raidPathWidth, 1, dist),
					cframe = CFrame.lookAt(mid, b) * CFrame.new(0, -0.5, 0),
					color = Color3.fromRGB(50, 50, 60),
					material = Enum.Material.Concrete,
					parent = folder,
				})
			end
		end
	end

	if plotCount >= 3 then
		local a = plots[plotCount].origin
		local b = plots[1].origin
		local mid = (a + b) / 2
		local dist = (b - a).Magnitude
		part({
			name = `RaidPath_{plotCount}_1`,
			size = Vector3.new(PlotConfig.raidPathWidth, 1, dist),
			cframe = CFrame.lookAt(mid, b) * CFrame.new(0, -0.5, 0),
			color = Color3.fromRGB(50, 50, 60),
			material = Enum.Material.Concrete,
			parent = folder,
		})
	end

	return plots
end

return PlotBuilder
