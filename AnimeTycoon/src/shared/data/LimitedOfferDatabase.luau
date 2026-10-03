--!strict
-- Robux Limited stands under Base.Limited (RobStand1..). Product ids → Creator Hub before launch.

local ProductIds
if script and script.Parent then
    ProductIds = require(script.Parent.ProductIds)
else
    ProductIds = require("./ProductIds")
end

export type LimitedOffer = {
    standId: string,
    heroId: string,
    rarity: string,
    mutations: { string },
    --- Coins per mini (matches stand PerToy; may exceed RarityDatabase).
    incomePerMini: number,
    robuxPrice: number,
    productId: number,
    stockMax: number,
}

--[[
  Mirror Workspace.Base.Limited billboards (Edit-time authoring).
  Mutation typos on mesh UI (Prysmatic) normalized in LimitedLogic.
]]
local OFFERS: { LimitedOffer } = {
    {
        standId = "RobStand1",
        heroId = "Orcalero Orcala",
        rarity = "legendary",
        mutations = { "secret" },
        incomePerMini = 1_500_000, -- $1.5M/Toy
        robuxPrice = 499,
        productId = 0, -- ProductIds.LimitedRobStand1
        stockMax = 500,
    },
    {
        standId = "RobStand2",
        heroId = "La_Vacca_Saturno_Saturnita",
        rarity = "mythic",
        mutations = { "galaxy" },
        incomePerMini = 1.5e15, -- $1.5Qd/Toy
        robuxPrice = 1299,
        productId = 0,
        stockMax = 500,
    },
    {
        standId = "RobStand3",
        heroId = "Dragon Cannelloni",
        -- Billboard Rare on stand is authored "Null" (RarityShine), not Legendary.
        rarity = "null",
        mutations = { "prismatic" },
        incomePerMini = 6.2e24, -- $6.2Qc/Toy (authoring)
        robuxPrice = 3999,
        productId = 0,
        stockMax = 500,
    },
}

local byStand: { [string]: LimitedOffer } = {}
local byProduct: { [number]: LimitedOffer } = {}

local function refreshIndexes()
    table.clear(byStand)
    table.clear(byProduct)
    for _, offer in OFFERS do
        byStand[offer.standId] = offer
        local id = offer.productId
        if typeof(id) == "number" and id > 0 then
            byProduct[id] = offer
        end
    end
end

refreshIndexes()

local LimitedOfferDatabase = {}

function LimitedOfferDatabase.all(): { LimitedOffer }
    return OFFERS
end

function LimitedOfferDatabase.get(standId: string): LimitedOffer?
    return byStand[standId]
end

function LimitedOfferDatabase.getByProductId(productId: number): LimitedOffer?
    return byProduct[productId]
end

--- Wire product ids from ProductIds after Creator Hub setup.
function LimitedOfferDatabase.applyProductIds()
    local map = {
        RobStand1 = (ProductIds :: any).LimitedRobStand1,
        RobStand2 = (ProductIds :: any).LimitedRobStand2,
        RobStand3 = (ProductIds :: any).LimitedRobStand3,
    }
    for _, offer in OFFERS do
        local id = map[offer.standId]
        if typeof(id) == "number" then
            offer.productId = id
        end
    end
    refreshIndexes()
end

LimitedOfferDatabase.applyProductIds()

return LimitedOfferDatabase
