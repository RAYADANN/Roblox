--!strict

-- Minecraft-style voxel place: click face → adjacent cube. Shift+click → take.
-- Q cycles block type (dirt / spikes / …).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotConfig = require(ReplicatedStorage.shared.data.PlotConfig)
local NetClient = require(script.Parent.Parent.net.NetClient)

local CELL = PlotConfig.cellSize
local MAX_LAYER = 6
local CYCLE = { "dirt", "spikes", "wood_planks", "stone", "nest_deco" }

local BuildController = {}
BuildController.__index = BuildController

export type BuildController = typeof(setmetatable(
	{} :: {
		_net: NetClient.NetClient,
		_enabled: boolean,
		_ghost: Part?,
		_grid: Folder?,
		_blockId: string,
		_inventory: { [string]: number },
		_target: { x: number, y: number, z: number }?,
		_connections: { RBXScriptConnection },
		_onChanged: ((boolean, string) -> ())?,
	},
	BuildController
))

function BuildController.new(net: NetClient.NetClient): BuildController
	return setmetatable({
		_net = net,
		_enabled = false,
		_ghost = nil,
		_grid = nil,
		_blockId = "dirt",
		_inventory = { dirt = 0, spikes = 0 },
		_target = nil,
		_connections = {},
		_onChanged = nil,
	}, BuildController)
end

function BuildController:isEnabled(): boolean
	return self._enabled
end

function BuildController:getBlockId(): string
	return self._blockId
end

function BuildController:onChanged(cb: (boolean, string) -> ())
	self._onChanged = cb
end

function BuildController:setInventory(blocks: { [string]: number })
	self._inventory = blocks
	if (self._inventory[self._blockId] or 0) <= 0 then
		self:_pickFirstOwned()
	end
end

function BuildController:_pickFirstOwned()
	for _, id in CYCLE do
		if (self._inventory[id] or 0) > 0 then
			self._blockId = id
			return
		end
	end
	self._blockId = "dirt"
end

function BuildController:_cycleBlock()
	local start = table.find(CYCLE, self._blockId) or 1
	for i = 1, #CYCLE do
		local idx = ((start - 1 + i) % #CYCLE) + 1
		local id = CYCLE[idx]
		if (self._inventory[id] or 0) > 0 then
			self._blockId = id
			self:_restyleGhost()
			if self._onChanged then
				self._onChanged(self._enabled, self._blockId)
			end
			return
		end
	end
end

local function snapCell(v: number): number
	return math.floor(v / CELL + 0.5) * CELL
end

local function dominantAxis(n: Vector3): Vector3
	local ax, ay, az = math.abs(n.X), math.abs(n.Y), math.abs(n.Z)
	if ay >= ax and ay >= az then
		return Vector3.new(0, if n.Y >= 0 then 1 else -1, 0)
	elseif ax >= az then
		return Vector3.new(if n.X >= 0 then 1 else -1, 0, 0)
	end
	return Vector3.new(0, 0, if n.Z >= 0 then 1 else -1)
end

function BuildController:_clearGhost()
	if self._ghost then
		self._ghost:Destroy()
		self._ghost = nil
	end
	self._target = nil
end

function BuildController:_clearGrid()
	if self._grid then
		self._grid:Destroy()
		self._grid = nil
	end
end

function BuildController:_findOwnPlot(): (Model?, Vector3?)
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return nil, nil
	end
	local userId = Players.LocalPlayer.UserId
	for _, child in plots:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("OwnerUserId") == userId then
			local yard = child:FindFirstChild("YardFloor")
			if yard and yard:IsA("BasePart") then
				return child, yard.Position
			end
		end
	end
	return nil, nil
end

function BuildController:_showGrid(_plot: Model, origin: Vector3)
	self:_clearGrid()
	local folder = Instance.new("Folder")
	folder.Name = "BuildGridLocal"
	folder.Parent = Workspace
	self._grid = folder

	local half = PlotConfig.yardSize.X / 2
	for x = -half + CELL, half - CELL, CELL do
		for z = -half + CELL, half - CELL, CELL do
			local p = Instance.new("Part")
			p.Name = "Cell"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.Size = Vector3.new(CELL - 0.2, 0.06, CELL - 0.2)
			p.Color = Color3.fromRGB(255, 240, 120)
			p.Material = Enum.Material.Neon
			p.Transparency = 0.88
			p.CFrame = CFrame.new(origin.X + x, 0.08, origin.Z + z)
			p.Parent = folder
		end
	end
end

function BuildController:_restyleGhost()
	local ghost = self._ghost
	if not ghost then
		return
	end
	local isTrap = self._blockId == "spikes"
	if isTrap then
		ghost.Size = Vector3.new(CELL * 0.95, 0.7, CELL * 0.95)
		ghost.Color = Color3.fromRGB(255, 90, 80)
	else
		ghost.Size = Vector3.new(CELL * 0.98, CELL * 0.98, CELL * 0.98)
		ghost.Color = Color3.fromRGB(100, 220, 120)
	end
end

function BuildController:_ensureGhost(): Part
	if self._ghost then
		self:_restyleGhost()
		return self._ghost
	end
	local ghost = Instance.new("Part")
	ghost.Name = "BuildGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.Material = Enum.Material.Neon
	ghost.Transparency = 0.4
	ghost.Parent = Workspace
	local box = Instance.new("SelectionBox")
	box.Adornee = ghost
	box.Color3 = Color3.fromRGB(180, 255, 180)
	box.LineThickness = 0.04
	box.Parent = ghost
	self._ghost = ghost
	self:_restyleGhost()
	return ghost
end

function BuildController:_raycast(screenPos: Vector2): RaycastResult?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = {}
	if self._ghost then
		table.insert(exclude, self._ghost)
	end
	if self._grid then
		table.insert(exclude, self._grid)
	end
	local character = Players.LocalPlayer.Character
	if character then
		table.insert(exclude, character)
	end
	params.FilterDescendantsInstances = exclude
	return Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
end

function BuildController:_resolveTarget(origin: Vector3, plot: Model, result: RaycastResult): (number?, number?, number?)
	local hit = result.Instance
	local half = PlotConfig.yardSize.X / 2 - CELL / 2
	local trapsOnlyGround = self._blockId == "spikes"

	if hit:GetAttribute("PlaceableId") ~= nil and hit:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
		local cx = hit:GetAttribute("CellX")
		local cy = hit:GetAttribute("CellY")
		local cz = hit:GetAttribute("CellZ")
		if typeof(cx) == "number" and typeof(cy) == "number" and typeof(cz) == "number" then
			local face = dominantAxis(result.Normal)
			local nx = cx + face.X * CELL
			local ny = cy + math.floor(face.Y + 0.5)
			local nz = cz + face.Z * CELL
			if trapsOnlyGround then
				ny = 0
			end
			if math.abs(nx) <= half and math.abs(nz) <= half and ny >= 0 and ny <= MAX_LAYER then
				return nx, ny, nz
			end
			return nil, nil, nil
		end
	end

	local inYard = hit:GetAttribute("IsYard") == true
		or hit.Name == "YardFloor"
		or (
			math.abs(result.Position.X - origin.X) <= PlotConfig.yardSize.X / 2
			and math.abs(result.Position.Z - origin.Z) <= PlotConfig.yardSize.Y / 2
			and result.Position.Y < 2
		)

	if not inYard and not hit:IsDescendantOf(plot) then
		return nil, nil, nil
	end

	local lx = snapCell(result.Position.X - origin.X)
	local lz = snapCell(result.Position.Z - origin.Z)
	if math.abs(lx) > half or math.abs(lz) > half then
		return nil, nil, nil
	end
	return lx, 0, lz
end

function BuildController:_updateGhost(screenPos: Vector2)
	if not self._enabled then
		return
	end
	local plot, origin = self:_findOwnPlot()
	if not plot or not origin then
		self:_clearGhost()
		return
	end
	local result = self:_raycast(screenPos)
	if not result then
		self:_clearGhost()
		return
	end
	local x, y, z = self:_resolveTarget(origin, plot, result)
	if x == nil or y == nil or z == nil then
		self:_clearGhost()
		return
	end
	self._target = { x = x, y = y, z = z }
	local ghost = self:_ensureGhost()
	local isTrap = self._blockId == "spikes"
	local worldY = if isTrap then 0.35 else y * CELL + CELL / 2
	ghost.CFrame = CFrame.new(origin + Vector3.new(x, worldY, z))
end

function BuildController:_tryClick(screenPos: Vector2, takeMode: boolean)
	local plot, origin = self:_findOwnPlot()
	if not plot or not origin then
		return
	end
	local result = self:_raycast(screenPos)
	if not result then
		return
	end

	if takeMode then
		local hit = result.Instance
		if hit:GetAttribute("PlaceableId") and hit:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
			local id = hit:GetAttribute("PlaceableId")
			if typeof(id) == "string" then
				self._net:requestTakeBlock(id)
			end
		end
		return
	end

	if (self._inventory[self._blockId] or 0) <= 0 then
		return
	end

	local x, y, z = self:_resolveTarget(origin, plot, result)
	if x == nil or y == nil or z == nil then
		return
	end
	self._net:placeCube(self._blockId, x, y, z)
end

function BuildController:setEnabled(enabled: boolean)
	self._enabled = enabled
	if enabled then
		local plot, origin = self:_findOwnPlot()
		if plot and origin then
			self:_showGrid(plot, origin)
		end
	else
		self:_clearGhost()
		self:_clearGrid()
	end
	if self._onChanged then
		self._onChanged(enabled, self._blockId)
	end
end

function BuildController:toggle()
	self:setEnabled(not self._enabled)
end

function BuildController:start()
	table.insert(
		self._connections,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.B then
				self:toggle()
				return
			end
			if not self._enabled then
				return
			end
			if input.KeyCode == Enum.KeyCode.Q then
				self:_cycleBlock()
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local loc = UserInputService:GetMouseLocation()
				local take = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
				self:_tryClick(loc, take)
			elseif input.UserInputType == Enum.UserInputType.Touch then
				self:_tryClick(input.Position, false)
			end
		end)
	)

	table.insert(
		self._connections,
		RunService.RenderStepped:Connect(function()
			if not self._enabled then
				return
			end
			self:_updateGhost(UserInputService:GetMouseLocation())
		end)
	)
end

function BuildController:destroy()
	self:setEnabled(false)
	for _, c in self._connections do
		c:Disconnect()
	end
	table.clear(self._connections)
end

return BuildController
