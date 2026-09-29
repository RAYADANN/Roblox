--!strict
-- App HUD types + Zap encode/decode (JSON blobs for offers/slots/inventory).

local HttpService = game:GetService("HttpService")

local HudPayloadModule = require(script.Parent.Parent.types.HudPayload)

export type OfferHud = HudPayloadModule.OfferHud
export type SlotHud = HudPayloadModule.SlotHud
export type InvHud = HudPayloadModule.InvHud
export type HudSyncPayload = HudPayloadModule.HudPayload

export type ZapPlayerDataSync = {
    coins: number,
    plotId: number,
    favoriteBank: number,
    handUid: string,
    handName: string,
    offersJson: string,
    slotsJson: string,
    inventoryJson: string,
}

export type WorldExhibitPub = {
    ownerUserId: number,
    plotId: number,
    slotIndex: number,
    uid: string,
    templateId: string,
    rarity: string,
    displayName: string,
    progress: number,
    remainingSec: number,
    evolveDurationSec: number,
    incomeRate: number,
    highlightT: number,
    npcTarget: number,
    evolved: boolean,
    mutated: boolean,
    mutationStacks: number,
    mutationLabel: string,
    celebrateUntil: number,
    celebrateKind: string,
    animId: string,
    sellPrice: number,
    auctionValue: number?,
    scale: number,
    sizeId: string?,
    colorRgb: { number },
    -- Auction spectacle (exhibit held off income but still rendered on stand).
    auctioning: boolean?,
    auctionPhase: string?, -- "" | "running" | "finished" | "sold"
    auctionBidsJson: string?, -- revealed bids [{buyerName,amount},...]
    auctionCurrentBid: number?,
    auctionBidderCount: number?,
    isFavorite: boolean?,
}

export type ActionResult = {
    success: boolean,
    error: string?,
    coins: number?,
}

local NetTypes = {}

function NetTypes.toZapSync(payload: HudSyncPayload): ZapPlayerDataSync
    return {
        coins = payload.coins,
        plotId = payload.plotId,
        favoriteBank = payload.favoriteBank or 0,
        handUid = payload.handUid or "",
        handName = payload.handName or "",
        offersJson = HttpService:JSONEncode(payload.offers),
        slotsJson = HttpService:JSONEncode(payload.slots),
        inventoryJson = HttpService:JSONEncode(payload.inventory or {}),
    }
end

function NetTypes.fromZapSync(value: ZapPlayerDataSync): HudSyncPayload
    local offers: { OfferHud } = {}
    local slots: { SlotHud } = {}
    local inventory: { InvHud } = {}
    local okOffers, decodedOffers = pcall(function()
        return HttpService:JSONDecode(value.offersJson)
    end)
    if okOffers and typeof(decodedOffers) == "table" then
        offers = decodedOffers :: { OfferHud }
    end
    local okSlots, decodedSlots = pcall(function()
        return HttpService:JSONDecode(value.slotsJson)
    end)
    if okSlots and typeof(decodedSlots) == "table" then
        slots = decodedSlots :: { SlotHud }
    end
    local okInv, decodedInv = pcall(function()
        return HttpService:JSONDecode(value.inventoryJson)
    end)
    if okInv and typeof(decodedInv) == "table" then
        inventory = decodedInv :: { InvHud }
    end
    return {
        coins = value.coins,
        plotId = value.plotId,
        favoriteBank = value.favoriteBank or 0,
        offers = offers,
        slots = slots,
        inventory = inventory,
        handUid = if value.handUid ~= "" then value.handUid else nil,
        handName = if value.handName ~= "" then value.handName else nil,
    }
end

function NetTypes.encodeWorld(pubs: { WorldExhibitPub }): string
    return HttpService:JSONEncode(pubs)
end

function NetTypes.decodeWorld(json: string): { WorldExhibitPub }
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    if ok and typeof(decoded) == "table" then
        return decoded :: { WorldExhibitPub }
    end
    return {}
end

return NetTypes
