--!strict
-- Проекция PlayerData → HudPayload. Pure, тестируемо.
local req: any = require
local PlayerDataModule = if script
    then req(script.Parent.Parent.types.PlayerData)
    else req("@shared/types/PlayerData")
local HudPayloadModule = if script
    then req(script.Parent.Parent.types.HudPayload)
    else req("@shared/types/HudPayload")
local SkinDatabaseModule = if script
    then req(script.Parent.Parent.data.SkinDatabase)
    else req("@shared/data/SkinDatabase")

type PlayerData = PlayerDataModule.PlayerData
type HudPayload = HudPayloadModule.HudPayload

local buildHudPayload = {}

local function ownedIds(data: PlayerData): { string }
    local ids = {}
    for _, id in SkinDatabaseModule.listIds() do
        if data.ownedSkins[id] == true then
            table.insert(ids, id)
        end
    end
    return ids
end

function buildHudPayload.fromPlayerData(data: PlayerData): HudPayload
    return {
        wins = data.wins,
        losses = data.losses,
        equippedSkinId = data.equippedSkinId,
        lookSensitivity = data.lookSensitivity,
        crosshairId = data.crosshairId or "classic",
        ownedSkinIds = ownedIds(data),
    }
end

return buildHudPayload
