--!strict
-- 3D-питомцы других игроков (читаем DD_EquippedPets с Player).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetEquippedSync = require(ReplicatedStorage:WaitForChild("shared").util.PetEquippedSync)
local PetFollowerController = require(script.Parent.PetFollowerController)

local RemotePetVisual = {}

type PlayerBinding = {
	controller: PetFollowerController.Controller?,
	charConn: RBXScriptConnection?,
	attrConn: RBXScriptConnection?,
}

local _bindings: { [number]: PlayerBinding } = {}
local _started = false

local function characterRoot(player: Player): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function applyAttribute(player: Player, binding: PlayerBinding)
	local slots = PetEquippedSync.decode(player:GetAttribute(PetEquippedSync.ATTRIBUTE))
	if #slots == 0 then
		if binding.controller then
			binding.controller:destroy()
			binding.controller = nil
		end
		return
	end
	if not binding.controller then
		binding.controller = PetFollowerController.bind(function()
			return characterRoot(player)
		end)
	end
	binding.controller:setSlots(slots)
end

local function unbindPlayer(userId: number)
	local binding = _bindings[userId]
	if not binding then
		return
	end
	if binding.charConn then
		binding.charConn:Disconnect()
	end
	if binding.attrConn then
		binding.attrConn:Disconnect()
	end
	if binding.controller then
		binding.controller:destroy()
	end
	_bindings[userId] = nil
end

local function bindPlayer(player: Player)
	if player == Players.LocalPlayer then
		return
	end
	unbindPlayer(player.UserId)

	local binding: PlayerBinding = {}
	_bindings[player.UserId] = binding

	binding.attrConn = player:GetAttributeChangedSignal(PetEquippedSync.ATTRIBUTE):Connect(function()
		applyAttribute(player, binding)
	end)

	binding.charConn = player.CharacterAdded:Connect(function()
		if binding.controller then
			binding.controller:destroy()
			binding.controller = nil
		end
		task.defer(function()
			applyAttribute(player, binding)
		end)
	end)

	applyAttribute(player, binding)
end

function RemotePetVisual.start()
	if _started then
		return
	end
	_started = true

	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		unbindPlayer(player.UserId)
	end)
end

function RemotePetVisual.destroy()
	for userId in pairs(_bindings) do
		unbindPlayer(userId)
	end
	_started = false
end

return RemotePetVisual
