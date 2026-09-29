--!strict
-- App HUD sync types. Zap wire format in net.zap (JSON blobs for offers/slots).

export type HudSyncPayload = {
    coins: number,
    rebirths: number,
    upgrades: { [string]: number },
    handUid: string,
    offersJson: string,
    slotsJson: string,
    inventoryJson: string,
}

export type BuyUpgradeResult = {
    success: boolean,
    error: string?,
    coins: number?,
}

export type NotifyPayload = {
    kind: string,
    payload: string,
}

export type ZapPlayerDataSync = {
    coins: number,
    rebirths: number,
    pickaxe: number,
    backpack: number,
    handUid: string,
    offersJson: string,
    slotsJson: string,
    inventoryJson: string,
}

local HttpService = game:GetService("HttpService")

local NetTypes = {}

local function encode(value: any): string
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(value)
    end)
    if ok and typeof(encoded) == "string" then
        return encoded
    end
    return "[]"
end

function NetTypes.toZapSync(payload: HudSyncPayload): ZapPlayerDataSync
    return {
        coins = payload.coins,
        rebirths = payload.rebirths,
        pickaxe = payload.upgrades.pickaxe or 0,
        backpack = payload.upgrades.backpack or 0,
        handUid = payload.handUid,
        offersJson = payload.offersJson,
        slotsJson = payload.slotsJson,
        inventoryJson = payload.inventoryJson,
    }
end

function NetTypes.fromZapSync(value: ZapPlayerDataSync): HudSyncPayload
    return {
        coins = value.coins,
        rebirths = value.rebirths,
        upgrades = {
            pickaxe = value.pickaxe,
            backpack = value.backpack,
        },
        handUid = value.handUid,
        offersJson = value.offersJson,
        slotsJson = value.slotsJson,
        inventoryJson = value.inventoryJson,
    }
end

function NetTypes.encodeOffers(offers: { any }): string
    return encode(offers)
end

function NetTypes.encodeSlots(slots: { any }): string
    return encode(slots)
end

function NetTypes.encodeInventory(inventory: { any }): string
    return encode(inventory)
end

function NetTypes.decodeJsonArray(raw: string): { any }
    if typeof(raw) ~= "string" or raw == "" then
        return {}
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if ok and typeof(decoded) == "table" then
        return decoded :: { any }
    end
    return {}
end

-- HudPayload (typed) → wire HudSyncPayload
function NetTypes.fromHudPayload(hud: any): HudSyncPayload
    return {
        coins = hud.coins,
        rebirths = hud.rebirths,
        upgrades = hud.upgrades or {},
        handUid = hud.handUid or "",
        offersJson = NetTypes.encodeOffers(hud.offers or {}),
        slotsJson = NetTypes.encodeSlots(hud.slots or {}),
        inventoryJson = NetTypes.encodeInventory(hud.inventory or {}),
    }
end

return NetTypes
