--!strict
-- Локальные 3D-питомцы игрока (обёртка над PetFollowerController).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetLogic = require(ReplicatedStorage:WaitForChild("shared").util.PetLogic)
local PetFollowerController = require(script.Parent.Parent.core.PetFollowerController)

local PetVisual = {}

local _controller: PetFollowerController.Controller? = nil

local function getRoot(): BasePart?
	local player = Players.LocalPlayer
	local char = player and player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function ensureController(): PetFollowerController.Controller
	if not _controller then
		_controller = PetFollowerController.bind(getRoot)
	end
	return _controller
end

function PetVisual.setEquippedEntries(slots: { PetLogic.EquippedEntry })
	ensureController():setSlots(slots)
end

function PetVisual.setEquippedPets(petIds: { string })
	local slots: { PetLogic.EquippedEntry } = {}
	for i, petId in ipairs(petIds) do
		if typeof(petId) == "string" and petId ~= "" then
			table.insert(slots, { uid = "legacy_" .. tostring(i) .. "_" .. petId, petId = petId })
		end
	end
	PetVisual.setEquippedEntries(slots)
end

function PetVisual.setEquipped(petId: string?)
	if petId and petId ~= "" then
		PetVisual.setEquippedEntries({ { uid = "legacy_single", petId = petId } })
	else
		PetVisual.setEquippedEntries({})
	end
end

function PetVisual.destroy()
	if _controller then
		_controller:destroy()
		_controller = nil
	end
end

return PetVisual
