--!strict
-- Телепорт Area1 ↔ Area2 с поддержкой StreamingEnabled.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.shared.util.Logger)

local TeleportManager = {}
TeleportManager.__index = TeleportManager

local function getTeleporter(areaId: string): (BasePart?, ProximityPrompt?)
	local scriptabled = workspace:FindFirstChild("Scriptabled")
	if not scriptabled then
		return nil, nil
	end
	local area = scriptabled:FindFirstChild(areaId)
	if not area then
		return nil, nil
	end
	local part = area:FindFirstChild("teleporter")
	if not part or not part:IsA("BasePart") then
		return nil, nil
	end
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	return part, prompt
end

local function destinationPosition(fromArea: string): Vector3?
	local targetArea = if fromArea == "Area1" then "Area2" else "Area1"
	local teleporter = getTeleporter(targetArea)
	if not teleporter then
		return nil
	end
	-- Поставить игрока рядом с шаром, чуть выше
	return teleporter.Position + Vector3.new(6, 4, 0)
end

function TeleportManager.new()
	return setmetatable({ _started = false, _busy = {} :: { [Player]: boolean } }, TeleportManager)
end

function TeleportManager:_teleport(player: Player, fromArea: string)
	if self._busy[player] then
		return
	end
	local dest = destinationPosition(fromArea)
	if not dest then
		Logger.warn("TeleportManager", `no destination from {fromArea}`)
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	self._busy[player] = true

	task.spawn(function()
		local ok, err = pcall(function()
			-- Подгрузить целевую зону до PivotTo (StreamingEnabled)
			player:RequestStreamAroundAsync(dest)
			task.wait(0.15)
			if player.Character ~= character then
				return
			end
			character:PivotTo(CFrame.new(dest))
		end)
		if not ok then
			Logger.warn("TeleportManager", `teleport failed: {err}`)
		end
		task.wait(0.5)
		self._busy[player] = false
	end)
end

function TeleportManager:_wire(areaId: string)
	local part, prompt = getTeleporter(areaId)
	if not part or not prompt then
		Logger.warn("TeleportManager", `teleporter missing in {areaId}`)
		return
	end

	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Teleport"
	prompt.ObjectText = if areaId == "Area1" then "Area 2" else "Area 1"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("FromArea", areaId)

	prompt.Triggered:Connect(function(player: Player)
		self:_teleport(player, areaId)
	end)
end

function TeleportManager:start()
	if self._started then
		return
	end
	self._started = true
	task.spawn(function()
		local deadline = os.clock() + 30
		while os.clock() < deadline do
			local _, p1 = getTeleporter("Area1")
			local _, p2 = getTeleporter("Area2")
			if p1 and p2 then
				break
			end
			task.wait(0.25)
		end
		self:_wire("Area1")
		self:_wire("Area2")
		Logger.info("TeleportManager", "started")
	end)
end

return TeleportManager
