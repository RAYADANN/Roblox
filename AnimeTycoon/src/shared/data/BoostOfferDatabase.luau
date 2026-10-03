--!strict
-- Right-rail Robux boost offers (LuckyX2 / LuckyX4 / MoneyX2Gold).
-- Product ids → ProductIds (0 until Creator Hub). Images = Base.* BillboardGui.

local ProductIds
if script and script.Parent then
    ProductIds = require(script.Parent.ProductIds)
else
    ProductIds = require("./ProductIds")
end

export type BoostOfferId = "lucky_x2" | "lucky_x4" | "money_x2"

export type BoostOffer = {
    id: BoostOfferId,
    --- Workspace.Base child with authored BillboardGui.
    worldModelName: string,
    title: string,
    --- Billboard ImageLabel asset.
    image: string,
    --- Sale price shown in HUD (Robux).
    robux: number,
    --- Strikethrough “was” price.
    robuxWas: number,
    productKey: string,
    productId: number,
    --- Profile ownership field.
    ownedField: string,
}

--[[
  Mirror Workspace.Base.LuckyX2 / LuckyX4 / MoneyX2Gold billboards.
]]
local OFFERS: { BoostOffer } = {
    {
        id = "lucky_x2",
        worldModelName = "LuckyX2",
        title = "Lucky X2",
        image = "rbxassetid://117532383638584",
        robux = 10,
        robuxWas = 49,
        productKey = "LuckyX2",
        productId = 0,
        ownedField = "ownsLuckyX2",
    },
    {
        id = "lucky_x4",
        worldModelName = "LuckyX4",
        title = "Lucky X4",
        image = "rbxassetid://131608268488167",
        robux = 10,
        robuxWas = 49,
        productKey = "LuckyX4",
        productId = 0,
        ownedField = "ownsLuckyX4",
    },
    {
        id = "money_x2",
        worldModelName = "MoneyX2Gold",
        title = "Money X2",
        image = "rbxassetid://138510376717252",
        robux = 10,
        robuxWas = 49,
        productKey = "MoneyX2Gold",
        productId = 0,
        ownedField = "ownsMoneyX2",
    },
}

local byId: { [string]: BoostOffer } = {}
local byProduct: { [number]: BoostOffer } = {}

local function refreshIndexes()
    table.clear(byId)
    table.clear(byProduct)
    for _, offer in OFFERS do
        byId[offer.id] = offer
        local id = offer.productId
        if typeof(id) == "number" and id > 0 then
            byProduct[id] = offer
        end
    end
end

refreshIndexes()

local BoostOfferDatabase = {}

function BoostOfferDatabase.all(): { BoostOffer }
    return OFFERS
end

function BoostOfferDatabase.get(offerId: string): BoostOffer?
    return byId[offerId]
end

function BoostOfferDatabase.getByProductId(productId: number): BoostOffer?
    return byProduct[productId]
end

function BoostOfferDatabase.applyProductIds()
    local map = {
        lucky_x2 = (ProductIds :: any).LuckyX2,
        lucky_x4 = (ProductIds :: any).LuckyX4,
        money_x2 = (ProductIds :: any).MoneyX2Gold,
    }
    for _, offer in OFFERS do
        local id = map[offer.id]
        if typeof(id) == "number" then
            offer.productId = id
        end
    end
    refreshIndexes()
end

BoostOfferDatabase.applyProductIds()

return BoostOfferDatabase
