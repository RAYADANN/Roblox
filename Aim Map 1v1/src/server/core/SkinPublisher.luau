--!strict
-- Publishes equipped + kill-flex skin ids so all clients can render.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.shared.data.Constants)

local SkinPublisher = {}

function SkinPublisher.publish(player: Player, equippedSkinId: string, flexSkinId: string?)
    if not player.Parent then
        return
    end
    player:SetAttribute(Constants.EQUIPPED_SKIN_ATTRIBUTE, equippedSkinId)
    player:SetAttribute(Constants.FLEX_SKIN_ATTRIBUTE, flexSkinId or "")
end

function SkinPublisher.clearFlex(player: Player)
    if not player.Parent then
        return
    end
    player:SetAttribute(Constants.FLEX_SKIN_ATTRIBUTE, "")
end

function SkinPublisher.visibleOf(player: Player): string
    local flex = player:GetAttribute(Constants.FLEX_SKIN_ATTRIBUTE)
    if typeof(flex) == "string" and flex ~= "" then
        return flex
    end
    local equipped = player:GetAttribute(Constants.EQUIPPED_SKIN_ATTRIBUTE)
    if typeof(equipped) == "string" and equipped ~= "" then
        return equipped
    end
    return Constants.DEFAULT_SKIN_ID
end

return SkinPublisher
