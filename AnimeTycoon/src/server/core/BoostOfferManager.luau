--!strict
-- Server: grant / prompt right-rail Lucky & Money boost offers.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BoostOfferDatabase = require(ReplicatedStorage.shared.data.BoostOfferDatabase)
local BoostOfferLogic = require(ReplicatedStorage.shared.util.BoostOfferLogic)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local PlayerDataModule = require(ReplicatedStorage.shared.types.PlayerData)
local ProfileManager = require(script.Parent.ProfileManager)

type PlayerData = PlayerDataModule.PlayerData

export type Deps = {
    profileManager: ProfileManager.ProfileManager,
    syncHud: (player: Player) -> (),
    notify: (player: Player, kind: string, payload: string) -> (),
}

local BoostOfferManager = {}
BoostOfferManager.__index = BoostOfferManager

function BoostOfferManager.new(deps: Deps)
    return setmetatable({ _deps = deps }, BoostOfferManager)
end

function BoostOfferManager:markSeen(player: Player)
    local deps = (self :: any)._deps
    local changed = false
    deps.profileManager:mutate(player, function(d: PlayerData)
        if (d.boostOfferSeenAt or 0) <= 0 then
            d.boostOfferSeenAt = os.time()
            changed = true
        end
    end)
    if changed then
        deps.syncHud(player)
    end
end

function BoostOfferManager:grant(player: Player, offerId: string): boolean
    local offer = BoostOfferDatabase.get(offerId)
    if not offer then
        return false
    end
    local deps = (self :: any)._deps
    local granted = false
    local ok = deps.profileManager:mutate(player, function(d: PlayerData)
        if BoostOfferLogic.isOwned(d, offerId) then
            return
        end
        (d :: any)[offer.ownedField] = true
        granted = true
    end)
    if not ok or not granted then
        return false
    end
    deps.syncHud(player)
    deps.notify(player, "boost_owned", offerId)
    Logger.info("BoostOffer", `granted {offerId} → {player.Name}`)
    return true
end

function BoostOfferManager:grantByProductId(player: Player, productId: number): boolean
    local offer = BoostOfferDatabase.getByProductId(productId)
    if not offer then
        return false
    end
    return self:grant(player, offer.id)
end

function BoostOfferManager:canBuy(player: Player, offerId: string): (boolean, string?)
    local offer = BoostOfferDatabase.get(offerId)
    if not offer then
        return false, "unknown_offer"
    end
    local deps = (self :: any)._deps
    local data = deps.profileManager:get(player)
    if not data then
        return false, "no_profile"
    end
    if BoostOfferLogic.isOwned(data, offerId) then
        return false, "already_owned"
    end
    return true, nil
end

--- Prompt GamePass; Studio + id=0 grants immediately.
function BoostOfferManager:promptBuy(player: Player, offerId: string): (boolean, string?)
    local okBuy, err = self:canBuy(player, offerId)
    if not okBuy then
        return false, err
    end
    local offer = BoostOfferDatabase.get(offerId)
    if not offer then
        return false, "unknown_offer"
    end
    local id = offer.productId
    if typeof(id) ~= "number" or id <= 0 then
        if RunService:IsStudio() then
            Logger.info("BoostOffer", `Studio mock {offerId} for {player.Name}`)
            return self:grant(player, offerId), nil
        end
        return false, "product_unset"
    end
    MarketplaceService:PromptGamePassPurchase(player, id)
    return true, nil
end

return BoostOfferManager
