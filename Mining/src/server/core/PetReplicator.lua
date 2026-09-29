--!strict
-- Публикует экипированных питомцев на Player для клиентской визуализации.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetLogic = require(ReplicatedStorage:WaitForChild("shared").util.PetLogic)
local PetEquippedSync = require(ReplicatedStorage:WaitForChild("shared").util.PetEquippedSync)

local PetReplicator = {}

function PetReplicator.publish(player: Player, data: any)
	if not player or not player.Parent then
		return
	end
	local slots = PetLogic.getEquippedEntries(data)
	player:SetAttribute(PetEquippedSync.ATTRIBUTE, PetEquippedSync.encode(slots))
end

function PetReplicator.clear(player: Player)
	if not player or not player.Parent then
		return
	end
	player:SetAttribute(PetEquippedSync.ATTRIBUTE, "[]")
end

return PetReplicator
