--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local BlockDatabase = require(shared.data.BlockDatabase)
local CombatConfig = require(shared.data.CombatConfig)
local Remotes = require(shared.net.Remotes)
local BaseBuilder = require(script.Parent.BaseBuilder)

local Config = BlockDatabase.Config

type BaseServiceLike = {
	getPlotForPlayer: (self: any, player: Player) -> BaseBuilder.BasePlot?,
	getPlotByIndex: (self: any, index: number) -> BaseBuilder.BasePlot?,
	getOwner: (self: any, plot: BaseBuilder.BasePlot) -> Player?,
}

type EconomyLike = {
	tryConsumeBlock: (self: any, player: Player, blockId: string, qty: number) -> boolean,
	addBlockStack: (self: any, player: Player, blockId: string, qty: number) -> (),
	getBlockQty: (self: any, player: Player, blockId: string) -> number,
}

type LightLike = {
	attachToBlock: (self: any, block: BasePart, tier: number) -> (),
	detachFromBlock: (self: any, block: BasePart) -> (),
}

export type BuildService = {
	requestPlace: (
		self: BuildService,
		player: Player,
		cellX: number,
		cellY: number,
		cellZ: number,
		blockId: string
	) -> boolean,
	requestTake: (self: BuildService, player: Player, cellX: number, cellY: number, cellZ: number) -> boolean,
	applyBatHit: (self: BuildService, attacker: Player, block: BasePart) -> boolean,
	hasBlock: (self: BuildService, plot: BaseBuilder.BasePlot, cx: number, cy: number, cz: number) -> boolean,
	getTrapSlow: (self: BuildService, plot: BaseBuilder.BasePlot, worldPos: Vector3) -> number,
	destroy: (self: BuildService) -> (),
}

local BuildService = {}
BuildService.__index = BuildService

function BuildService.new(deps: {
	base: BaseServiceLike,
	economy: EconomyLike,
	lights: LightLike?,
}): BuildService
	local self = setmetatable({
		_base = deps.base,
		_economy = deps.economy,
		_lights = deps.lights,
		_conns = {} :: { RBXScriptConnection },
	}, BuildService)

	table.insert(
		self._conns,
		Remotes.RequestPlaceBlock.OnServerEvent:Connect(function(player: Player, cx: any, cy: any, cz: any, blockId: any)
			if typeof(cx) ~= "number" or typeof(cy) ~= "number" or typeof(cz) ~= "number" or typeof(blockId) ~= "string" then
				return
			end
			self:requestPlace(player, math.floor(cx + 0.5), math.floor(cy + 0.5), math.floor(cz + 0.5), blockId)
		end)
	)

	table.insert(
		self._conns,
		Remotes.RequestTakeBlock.OnServerEvent:Connect(function(player: Player, cx: any, cy: any, cz: any)
			if typeof(cx) ~= "number" or typeof(cy) ~= "number" or typeof(cz) ~= "number" then
				return
			end
			self:requestTake(player, math.floor(cx + 0.5), math.floor(cy + 0.5), math.floor(cz + 0.5))
		end)
	)

	return self
end

function BuildService:bindLights(lights: LightLike)
	self._lights = lights
end

function BuildService:hasBlock(plot: BaseBuilder.BasePlot, cx: number, cy: number, cz: number): boolean
	return plot.grid[Config.cellKey(cx, cy, cz)] ~= nil
end

function BuildService:getTrapSlow(plot: BaseBuilder.BasePlot, worldPos: Vector3): number
	local cx, _, cz = Config.worldToCell(plot.origin, worldPos)
	local block = plot.grid[Config.cellKey(cx, 0, cz)]
	if not block then
		return 1
	end
	local slow = block:GetAttribute("SlowFactor")
	if typeof(slow) == "number" then
		return slow
	end
	return 1
end

function BuildService:requestPlace(
	player: Player,
	cellX: number,
	cellY: number,
	cellZ: number,
	blockId: string
): boolean
	local def = BlockDatabase[blockId]
	local plot = self._base:getPlotForPlayer(player)
	if not def or not plot then
		return false
	end
	cellY = 0 -- PROVE single layer
	if not Config.isBuildableCell(cellX, cellY, cellZ) then
		Remotes.Toast:FireClient(player, "Can't build here")
		return false
	end
	local key = Config.cellKey(cellX, cellY, cellZ)
	if plot.grid[key] then
		return false
	end
	if plot.blockCount >= Config.MAX_PLACEABLES then
		Remotes.Toast:FireClient(player, "Placeable limit (40)")
		return false
	end
	if self._economy:getBlockQty(player, blockId) < 1 then
		Remotes.Toast:FireClient(player, "No blocks in inventory — Roll & Buy")
		return false
	end
	if not self._economy:tryConsumeBlock(player, blockId, 1) then
		return false
	end

	local block: BasePart
	if def.kind == "trap" then
		block = Instance.new("WedgePart")
		block.Size = Vector3.new(Config.CELL_SIZE * 0.9, 1.5, Config.CELL_SIZE * 0.9)
	else
		block = Instance.new("Part")
		block.Size = if def.kind == "lamp"
			then Vector3.new(2, 3, 2)
			else Config.CUBE_SIZE
	end
	block.Name = "Block_" .. blockId
	block.Anchored = true
	block.CanCollide = def.kind ~= "trap"
	block.Color = def.color
	block.Material = def.material
	local localPos = Config.cellToLocal(cellX, cellY, cellZ)
	if def.kind == "trap" then
		localPos = Vector3.new(localPos.X, Config.FLOOR_TOP_Y + 0.75, localPos.Z)
	elseif def.kind == "lamp" then
		localPos = Vector3.new(localPos.X, Config.FLOOR_TOP_Y + 1.5, localPos.Z)
	end
	block.CFrame = plot.origin * CFrame.new(localPos)
	block:SetAttribute("BlockId", blockId)
	block:SetAttribute("Kind", def.kind)
	block:SetAttribute("HP", def.batHitsToBreak)
	block:SetAttribute("MaxHP", def.batHitsToBreak)
	block:SetAttribute("PlotIndex", plot.index)
	block:SetAttribute("CellX", cellX)
	block:SetAttribute("CellY", cellY)
	block:SetAttribute("CellZ", cellZ)
	if def.slowFactor then
		block:SetAttribute("SlowFactor", def.slowFactor)
	end
	block.Parent = plot.model

	plot.grid[key] = block
	plot.blockCount += 1

	if def.kind == "lamp" and def.lampTier and self._lights then
		self._lights:attachToBlock(block, def.lampTier)
	end
	return true
end

function BuildService:requestTake(player: Player, cellX: number, cellY: number, cellZ: number): boolean
	local plot = self._base:getPlotForPlayer(player)
	if not plot then
		return false
	end
	cellY = 0
	local key = Config.cellKey(cellX, cellY, cellZ)
	local block = plot.grid[key]
	if not block then
		return false
	end
	local blockId = block:GetAttribute("BlockId")
	if typeof(blockId) ~= "string" then
		return false
	end
	if self._lights then
		self._lights:detachFromBlock(block)
	end
	plot.grid[key] = nil
	plot.blockCount = math.max(0, plot.blockCount - 1)
	block:Destroy()
	self._economy:addBlockStack(player, blockId, 1)
	return true
end

function BuildService:applyBatHit(attacker: Player, block: BasePart): boolean
	local plotIndex = block:GetAttribute("PlotIndex")
	if typeof(plotIndex) ~= "number" then
		return false
	end
	local plot = self._base:getPlotByIndex(plotIndex)
	if not plot then
		return false
	end
	local owner = self._base:getOwner(plot)
	if not owner or owner == attacker then
		return false
	end

	local root = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	if (root.Position - block.Position).Magnitude > CombatConfig.Steal.batRange + 6 then
		return false
	end

	local hp = block:GetAttribute("HP")
	if typeof(hp) ~= "number" then
		return false
	end
	hp -= 1
	block:SetAttribute("HP", hp)
	if hp > 0 then
		block.Color = block.Color:Lerp(Color3.fromRGB(40, 40, 40), 0.25)
		return true
	end

	local cx = block:GetAttribute("CellX")
	local cy = block:GetAttribute("CellY")
	local cz = block:GetAttribute("CellZ")
	if typeof(cx) == "number" and typeof(cy) == "number" and typeof(cz) == "number" then
		plot.grid[Config.cellKey(cx, cy, cz)] = nil
	end
	plot.blockCount = math.max(0, plot.blockCount - 1)
	if self._lights then
		self._lights:detachFromBlock(block)
	end
	block:Destroy()
	return true
end

function BuildService:destroy()
	for _, conn in self._conns do
		conn:Disconnect()
	end
end

return BuildService
