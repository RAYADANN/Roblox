--!strict

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockDatabase = require(ReplicatedStorage.shared.data.BlockDatabase)
local EconomyConfig = require(ReplicatedStorage.shared.data.EconomyConfig)
local PlotConfig = require(ReplicatedStorage.shared.data.PlotConfig)
local BlockLook = require(ReplicatedStorage.shared.util.BlockLook)
local Id = require(ReplicatedStorage.shared.util.Id)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local WorldUi = require(ReplicatedStorage.shared.ui.WorldUi)
local Remotes = require(ReplicatedStorage.shared.net.Remotes)
local SessionTypes = require(ReplicatedStorage.shared.types.Session)
local SessionService = require(script.Parent.SessionService)
local BaseService = require(script.Parent.BaseService)
local RateLimiter = require(script.Parent.util.RateLimiter)
local PlotBuilder = require(script.Parent.PlotBuilder)

type Placeable = SessionTypes.Placeable
type PlotModel = PlotBuilder.PlotModel

local MAX_LAYER = 6
local CELL = PlotConfig.cellSize

export type Deps = {
	sessionService: SessionService.SessionService,
	baseService: BaseService.BaseService,
	remotes: Remotes.RemotesApi,
	syncHud: (player: Player) -> (),
	notify: (player: Player, kind: string, payload: string) -> (),
}

local BuildService = {}
BuildService.__index = BuildService

export type BuildService = typeof(setmetatable(
	{} :: {
		_deps: Deps,
		_limit: RateLimiter.RateLimiter,
		_connections: { RBXScriptConnection },
		_parts: { [string]: BasePart },
	},
	BuildService
))

function BuildService.new(deps: Deps): BuildService
	return setmetatable({
		_deps = deps,
		_limit = RateLimiter.new(12, 1),
		_connections = {},
		_parts = {},
	}, BuildService)
end

local function snapCell(v: number): number
	return math.floor(v / CELL + 0.5) * CELL
end

local function cubeCFrame(origin: Vector3, lx: number, ly: number, lz: number): CFrame
	return CFrame.new(origin + Vector3.new(lx, ly * CELL + CELL / 2, lz))
end

function BuildService:_spawnCube(plot: PlotModel, placeable: Placeable, player: Player)
	local template = BlockDatabase.get(placeable.blockId)
	local isTrap = template ~= nil and template.kind == "trap"

	local cube = Instance.new("Part")
	cube.Name = placeable.id
	if isTrap then
		-- Flat hazard plate, not a full wall cube
		cube.Size = Vector3.new(CELL * 0.95, 0.7, CELL * 0.95)
		cube.CFrame = CFrame.new(plot.origin + Vector3.new(placeable.x, 0.35, placeable.z))
	else
		cube.Size = Vector3.new(CELL, CELL, CELL)
		cube.CFrame = cubeCFrame(plot.origin, placeable.x, placeable.y, placeable.z)
	end
	cube.Anchored = true
	cube.CanCollide = not isTrap -- traps are walk-through hazard zones
	BlockLook.apply(cube, placeable.blockId)
	cube:SetAttribute("PlaceableId", placeable.id)
	cube:SetAttribute("OwnerUserId", player.UserId)
	cube:SetAttribute("BlockId", placeable.blockId)
	cube:SetAttribute("PlotId", plot.id)
	cube:SetAttribute("CellX", placeable.x)
	cube:SetAttribute("CellY", placeable.y)
	cube:SetAttribute("CellZ", placeable.z)
	cube:SetAttribute("IsTrap", isTrap)
	cube.Parent = plot.buildFolder
	self._parts[placeable.id] = cube

	if isTrap then
		-- Visual spikes
		for i = 1, 5 do
			local spike = Instance.new("WedgePart")
			spike.Name = "Spike"
			spike.Anchored = true
			spike.CanCollide = false
			spike.Size = Vector3.new(0.6, 1.4, 0.6)
			spike.Color = Color3.fromRGB(220, 80, 70)
			spike.Material = Enum.Material.Metal
			local ox = ((i - 3) * 0.7)
			local oz = if i % 2 == 0 then 0.5 else -0.5
			spike.CFrame = cube.CFrame * CFrame.new(ox, 0.9, oz) * CFrame.Angles(0, 0, 0)
			spike.Parent = cube
		end
	else
		local highlight = Instance.new("SelectionBox")
		highlight.Name = "VoxelEdge"
		highlight.Adornee = cube
		highlight.Color3 = Color3.fromRGB(0, 0, 0)
		highlight.LineThickness = 0.02
		highlight.Transparency = 0.65
		highlight.Parent = cube
	end

	local take = Instance.new("ProximityPrompt")
	take.Name = "TakePrompt"
	take.ActionText = "Take"
	take.ObjectText = placeable.blockId
	take.HoldDuration = 0
	take.MaxActivationDistance = 12
	take.Parent = cube
	WorldUi.stylePrompt(take, "take")
end

function BuildService:place(player: Player, blockId: string, cellX: number, cellY: number, cellZ: number): boolean
	if not self._limit:allow(player) then
		return false
	end
	if typeof(blockId) ~= "string" or typeof(cellX) ~= "number" or typeof(cellY) ~= "number" or typeof(cellZ) ~= "number" then
		return false
	end
	local data = self._deps.sessionService:get(player)
	local plot = self._deps.baseService:getPlotForPlayer(player)
	if not data or not plot then
		return false
	end
	if (data.blockInventory[blockId] or 0) < 1 then
		self._deps.notify(player, "error", "No blocks")
		return false
	end
	if #data.placeables >= EconomyConfig.placeablesCap then
		self._deps.notify(player, "error", "Placeable cap")
		return false
	end
	local template = BlockDatabase.get(blockId)
	if not template then
		return false
	end

	local lx = snapCell(cellX)
	local lz = snapCell(cellZ)
	local ly = math.floor(cellY + 0.5)
	if ly < 0 or ly > MAX_LAYER then
		self._deps.notify(player, "error", "Too high")
		return false
	end

	local half = PlotConfig.yardSize.X / 2 - CELL / 2
	if math.abs(lx) > half or math.abs(lz) > half then
		self._deps.notify(player, "error", "Only in Yard")
		return false
	end

	for _, p in data.placeables do
		if p.x == lx and p.y == ly and p.z == lz then
			self._deps.notify(player, "error", "Cell taken")
			return false
		end
	end

	-- Traps only on ground layer
	if template and template.kind == "trap" and ly ~= 0 then
		self._deps.notify(player, "error", "Traps on ground only")
		return false
	end

	-- Must rest on ground or another cube (Minecraft support)
	if ly > 0 then
		local supported = false
		for _, p in data.placeables do
			if p.x == lx and p.z == lz and p.y == ly - 1 then
				supported = true
				break
			end
		end
		if not supported then
			self._deps.notify(player, "error", "Needs support")
			return false
		end
	end

	data.blockInventory[blockId] -= 1
	local placeable: Placeable = {
		id = Id.new(),
		blockId = blockId,
		x = lx,
		y = ly,
		z = lz,
	}
	table.insert(data.placeables, placeable)
	self:_spawnCube(plot, placeable, player)
	self._deps.syncHud(player)
	Logger.debug("BuildService", `{player.Name} cube {blockId} @ {lx},{ly},{lz}`)
	return true
end

function BuildService:take(player: Player, placeableId: string): boolean
	if not self._limit:allow(player) then
		return false
	end
	local data = self._deps.sessionService:get(player)
	if not data then
		return false
	end
	local idx = nil
	for i, p in data.placeables do
		if p.id == placeableId then
			idx = i
			break
		end
	end
	if not idx then
		return false
	end
	local placeable = data.placeables[idx]

	-- Block take if cube above exists
	for _, p in data.placeables do
		if p.x == placeable.x and p.z == placeable.z and p.y == placeable.y + 1 then
			self._deps.notify(player, "error", "Remove above first")
			return false
		end
	end

	table.remove(data.placeables, idx)
	data.blockInventory[placeable.blockId] = (data.blockInventory[placeable.blockId] or 0) + 1
	local part = self._parts[placeableId]
	if part then
		part:Destroy()
		self._parts[placeableId] = nil
	end
	self._deps.syncHud(player)
	return true
end

function BuildService:start()
	table.insert(self._connections, self._deps.remotes.RequestPlaceBlock.OnServerEvent:Connect(function(player, blockId, x, y, z)
		-- Support both new (x,y,z) and legacy (x,z,rot) during transition
		if typeof(y) == "number" and typeof(z) == "number" then
			self:place(player, blockId, x, y, z)
		elseif typeof(x) == "number" and typeof(y) == "number" then
			-- legacy: x,z world-ish — treat y as z, layer 0
			self:place(player, blockId, x, 0, y)
		end
	end))
	table.insert(self._connections, self._deps.remotes.RequestTakeBlock.OnServerEvent:Connect(function(player, placeableId)
		if typeof(placeableId) == "string" then
			self:take(player, placeableId)
		end
	end))

	table.insert(
		self._connections,
		ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
			if prompt.Name ~= "TakePrompt" then
				return
			end
			local part = prompt.Parent
			if not part or not part:IsA("BasePart") then
				return
			end
			local placeableId = part:GetAttribute("PlaceableId")
			local ownerUserId = part:GetAttribute("OwnerUserId")
			if typeof(placeableId) == "string" and ownerUserId == player.UserId then
				self:take(player, placeableId)
			end
		end)
	)
end

function BuildService:destroy()
	for _, c in self._connections do
		c:Disconnect()
	end
	table.clear(self._connections)
end

return BuildService
