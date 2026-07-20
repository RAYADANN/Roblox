--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local Remotes = require(shared.net.Remotes)
local BlockDatabase = require(shared.data.BlockDatabase)

local Config = BlockDatabase.Config

export type BuildController = {
	destroy: (self: BuildController) -> (),
}

local BuildController = {}
BuildController.__index = BuildController

local function holdingTool(name: string): boolean
	local character = Players.LocalPlayer.Character
	if not character then
		return false
	end
	local tool = character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool.Name == name
end

function BuildController.new(getSelectedBlock: () -> string?): BuildController
	local self = setmetatable({
		_getSelected = getSelectedBlock,
		_ghost = nil :: Part?,
		_placeCell = nil :: { cx: number, cy: number, cz: number }?,
		_conns = {} :: { RBXScriptConnection },
	}, BuildController)

	table.insert(
		self._conns,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if holdingTool("Build") then
					self:_tryPlace()
				elseif holdingTool("Take") then
					self:_tryTake()
				end
			end
		end)
	)

	local function bindTool(tool: Tool)
		table.insert(self._conns, tool.Activated:Connect(function()
			if tool.Name == "Build" then
				self:_tryPlace()
			elseif tool.Name == "Take" then
				self:_tryTake()
			end
		end))
	end

	local function onCharacter(character: Model)
		for _, name in { "Build", "Take" } do
			local tool = character:FindFirstChild(name)
			if tool and tool:IsA("Tool") then
				bindTool(tool)
			end
		end
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and (child.Name == "Build" or child.Name == "Take") then
				bindTool(child)
			end
		end)
	end

	if Players.LocalPlayer.Character then
		onCharacter(Players.LocalPlayer.Character)
	end
	table.insert(self._conns, Players.LocalPlayer.CharacterAdded:Connect(onCharacter))

	table.insert(self._conns, RunService.RenderStepped:Connect(function()
		if holdingTool("Build") then
			self:_updateGhost()
		else
			self:_clearGhost()
		end
	end))

	return self
end

function BuildController:_clearGhost()
	if self._ghost then
		self._ghost:Destroy()
		self._ghost = nil
	end
	self._placeCell = nil
end

function BuildController:_ownPlotModel(): Model?
	local plots = Workspace:FindFirstChild("Plots")
	local idx = Players.LocalPlayer:GetAttribute("PlotIndex")
	if not plots or typeof(idx) ~= "number" then
		return nil
	end
	return plots:FindFirstChild("Plot_" .. idx) :: Model?
end

function BuildController:_plotOrigin(plotModel: Model): CFrame?
	local floor = plotModel:FindFirstChild("YardFloor") or plotModel:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		return floor.CFrame * CFrame.new(0, -0.5, 0)
	end
	return nil
end

function BuildController:_raycast(): RaycastResult?
	local camera = Workspace.CurrentCamera
	local mouse = Players.LocalPlayer:GetMouse()
	if not camera or not mouse then
		return nil
	end
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if self._ghost then
		table.insert(exclude, self._ghost)
	end
	local character = Players.LocalPlayer.Character
	if character then
		table.insert(exclude, character)
	end
	params.FilterDescendantsInstances = exclude
	return Workspace:Raycast(unitRay.Origin, unitRay.Direction * 80, params)
end

function BuildController:_resolveCell(origin: CFrame, result: RaycastResult): (number?, number?, number?)
	local hit = result.Instance
	local name = hit.Name
	if name == "YardFloor" or name == "Floor" or string.sub(name, 1, 5) == "Grid_" then
		local placeWorld = result.Position + Vector3.new(0, 0.1, 0)
		local cx, _, cz = Config.worldToCell(origin, placeWorld)
		return cx, 0, cz
	end
	if string.sub(name, 1, 6) == "Block_" then
		local placeWorld = result.Position + result.Normal * (Config.CELL_SIZE * 0.51)
		local cx, cy, cz = Config.worldToCell(origin, placeWorld)
		return cx, 0, cz
	end
	return nil, nil, nil
end

function BuildController:_updateGhost()
	local blockId = self._getSelected()
	local def = if blockId then BlockDatabase[blockId] else nil
	local plotModel = self:_ownPlotModel()
	if not def or not plotModel then
		self:_clearGhost()
		return
	end
	local origin = self:_plotOrigin(plotModel)
	if not origin then
		return
	end
	local result = self:_raycast()
	if not result or not result.Instance:IsDescendantOf(plotModel) then
		self:_clearGhost()
		return
	end
	local cx, cy, cz = self:_resolveCell(origin, result)
	if cx == nil or cy == nil or cz == nil then
		self:_clearGhost()
		return
	end
	if not Config.isBuildableCell(cx, cy, cz) then
		self:_clearGhost()
		return
	end

	self._placeCell = { cx = cx, cy = cy, cz = cz }
	if not self._ghost then
		local g = Instance.new("Part")
		g.Name = "BuildGhost"
		g.Anchored = true
		g.CanCollide = false
		g.Transparency = 0.45
		g.Material = Enum.Material.ForceField
		g.Parent = Workspace
		self._ghost = g
	end
	local ghost = self._ghost :: Part
	ghost.Size = if def.kind == "lamp" then Vector3.new(2, 3, 2) elseif def.kind == "trap" then Vector3.new(3.5, 1.5, 3.5) else Config.CUBE_SIZE
	ghost.Color = def.color
	ghost.CFrame = origin * CFrame.new(Config.cellToLocal(cx, cy, cz))
end

function BuildController:_tryPlace()
	local blockId = self._getSelected()
	local cell = self._placeCell
	if not blockId or not cell then
		return
	end
	Remotes.RequestPlaceBlock:FireServer(cell.cx, cell.cy, cell.cz, blockId)
end

function BuildController:_tryTake()
	local plotModel = self:_ownPlotModel()
	if not plotModel then
		return
	end
	local origin = self:_plotOrigin(plotModel)
	if not origin then
		return
	end
	local result = self:_raycast()
	if not result or not result.Instance:IsDescendantOf(plotModel) then
		return
	end
	if string.sub(result.Instance.Name, 1, 6) ~= "Block_" then
		return
	end
	local cx = result.Instance:GetAttribute("CellX")
	local cy = result.Instance:GetAttribute("CellY")
	local cz = result.Instance:GetAttribute("CellZ")
	if typeof(cx) == "number" and typeof(cy) == "number" and typeof(cz) == "number" then
		Remotes.RequestTakeBlock:FireServer(cx, cy, cz)
	end
end

function BuildController:destroy()
	self:_clearGhost()
	for _, conn in self._conns do
		conn:Disconnect()
	end
end

return BuildController
