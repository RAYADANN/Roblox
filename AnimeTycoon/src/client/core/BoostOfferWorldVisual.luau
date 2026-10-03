--!strict
-- Hide authored Base.Lucky*/Money* world billboards (HUD shows the same art).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local BoostOfferDatabase = require(ReplicatedStorage.shared.data.BoostOfferDatabase)

local BoostOfferWorldVisual = {}

function BoostOfferWorldVisual.start()
    local base = BaseLayout.getPrimary()
    if not base then
        return
    end
    for _, offer in BoostOfferDatabase.all() do
        local model = base:FindFirstChild(offer.worldModelName)
        if not model then
            continue
        end
        for _, d in model:GetDescendants() do
            if d:IsA("BillboardGui") then
                d.Enabled = false
            end
        end
    end
end

return BoostOfferWorldVisual
