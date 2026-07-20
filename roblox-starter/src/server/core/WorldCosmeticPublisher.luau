--!strict
-- Публикует косметическое состояние игрока для всех клиентов (attribute replication).
-- Вызывай после mutate профиля и при загрузке игрока.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttributeSync = require(ReplicatedStorage.shared.util.PlayerAttributeSync)

export type Slot = PlayerAttributeSync.Slot

local WorldCosmeticPublisher = {}

function WorldCosmeticPublisher.publish(player: Player, slots: { Slot })
	if not player.Parent then
		return
	end
	player:SetAttribute(PlayerAttributeSync.ATTRIBUTE, PlayerAttributeSync.encode(slots))
end

function WorldCosmeticPublisher.clear(player: Player)
	if not player.Parent then
		return
	end
	player:SetAttribute(PlayerAttributeSync.ATTRIBUTE, "[]")
end

return WorldCosmeticPublisher
