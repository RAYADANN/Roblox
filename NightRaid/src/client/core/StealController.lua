--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")
local Remotes = require(shared.net.Remotes)
local CombatConfig = require(shared.data.CombatConfig)

export type StealController = {
	destroy: (self: StealController) -> (),
}

local StealController = {}
StealController.__index = StealController

local function nearestThiefUserId(rootPos: Vector3): number?
	local bestDist = CombatConfig.Steal.batRange
	local bestId: number? = nil
	for _, player in Players:GetPlayers() do
		if player ~= Players.LocalPlayer then
			local stealing = player:GetAttribute("StealingPetId")
			if typeof(stealing) == "string" and stealing ~= "" then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local dist = (root.Position - rootPos).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestId = player.UserId
					end
				end
			end
		end
	end
	return bestId
end

local function nearestEnemyBlock(rootPos: Vector3): BasePart?
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	local localId = Players.LocalPlayer.UserId
	local bestDist = CombatConfig.Steal.batRange + 4
	local best: BasePart? = nil
	for _, plotModel in plots:GetChildren() do
		if plotModel:IsA("Model") then
			local ownerId = plotModel:GetAttribute("OwnerUserId")
			if typeof(ownerId) == "number" and ownerId ~= localId then
				for _, child in plotModel:GetChildren() do
					if child:IsA("BasePart") and string.sub(child.Name, 1, 6) == "Block_" then
						local dist = (child.Position - rootPos).Magnitude
						if dist < bestDist then
							bestDist = dist
							best = child
						end
					end
				end
			end
		end
	end
	return best
end

function StealController.new(): StealController
	local self = setmetatable({
		_conns = {} :: { RBXScriptConnection },
	}, StealController)

	table.insert(
		self._conns,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.E then
				Remotes.RequestSteal:FireServer()
			end
		end)
	)

	local function bindBat(tool: Tool)
		table.insert(
			self._conns,
			tool.Activated:Connect(function()
				local root = Players.LocalPlayer.Character
					and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not root or not root:IsA("BasePart") then
					return
				end
				local targetId = nearestThiefUserId(root.Position)
				if targetId then
					Remotes.BatHit:FireServer(targetId)
					return
				end
				local block = nearestEnemyBlock(root.Position)
				if block then
					Remotes.BatHitBlock:FireServer(block)
				end
			end)
		)
	end

	local function onCharacter(character: Model)
		task.defer(function()
			local bat = character:FindFirstChild("Bat") or Players.LocalPlayer.Backpack:FindFirstChild("Bat")
			if bat and bat:IsA("Tool") then
				bindBat(bat)
			end
		end)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child.Name == "Bat" then
				bindBat(child)
			end
		end)
	end

	if Players.LocalPlayer.Character then
		onCharacter(Players.LocalPlayer.Character)
	end
	table.insert(self._conns, Players.LocalPlayer.CharacterAdded:Connect(onCharacter))

	return self
end

function StealController:destroy()
	for _, conn in self._conns do
		conn:Disconnect()
	end
end

return StealController
