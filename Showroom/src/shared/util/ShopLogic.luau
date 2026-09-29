--!strict
-- Pure Shop helpers: adaptive pack grants + product cards for UI.

local FormatMoney
local ShopDatabase
if script and script.Parent then
    FormatMoney = require(script.Parent.FormatMoney)
    ShopDatabase = require(script.Parent.Parent.data.ShopDatabase)
else
    FormatMoney = require("./FormatMoney")
    ShopDatabase = require("../data/ShopDatabase")
end

export type LayoutKind = ShopDatabase.LayoutKind
export type HeroKind = ShopDatabase.HeroKind

export type Progress = {
    coins: number,
    incomePerSec: number?,
    rebirths: number?,
}

export type ProductCard = {
    id: string,
    title: string,
    description: string?,
    kind: LayoutKind,
    priceRobux: number,
    featured: boolean,
    plateKey: string,
    heroKey: string?,
    heroKind: HeroKind,
    aspectRatio: number,
    coinsGrant: number?,
}

local ShopLogic = {}

--- Soft scale so Robux packs stay useful vs current wealth without nuking early game.
function ShopLogic.progressScale(progress: Progress): number
    local coins = math.max(0, progress.coins)
    local income = math.max(0, progress.incomePerSec or 0)
    local rebirths = math.max(0, math.floor(progress.rebirths or 0))
    local wealth = math.log10(coins + 100)
    local incomeLog = math.log10(income + 5)
    -- Early game (~start coins / low income) stays near 1× base grant.
    return 1 + rebirths * 0.3 + math.max(0, wealth - 2.5) * 0.4 + math.max(0, incomeLog - 1.5) * 0.3
end

function ShopLogic.packGrant(baseGrant: number, progress: Progress): number
    local base = math.max(1, math.floor(baseGrant))
    local scaled = math.floor(base * ShopLogic.progressScale(progress) + 0.5)
    return math.max(base, scaled)
end

function ShopLogic.formatGrant(amount: number): string
    return `+{FormatMoney.short(amount)}`
end

function ShopLogic.products(progress: Progress?): { ProductCard }
    local p: Progress = progress or { coins = 0, incomePerSec = 0, rebirths = 0 }
    local out: { ProductCard } = table.create(#ShopDatabase.PRODUCTS)
    for i, def in ShopDatabase.PRODUCTS do
        local grant: number? = nil
        local title = def.title
        if def.baseGrant then
            grant = ShopLogic.packGrant(def.baseGrant, p)
            title = ShopLogic.formatGrant(grant)
        end
        out[i] = {
            id = def.id,
            title = title,
            description = def.description,
            kind = def.kind,
            priceRobux = def.priceRobux,
            featured = def.featured,
            plateKey = def.plateKey,
            heroKey = def.heroKey,
            heroKind = def.heroKind,
            aspectRatio = ShopDatabase.aspect(def),
            coinsGrant = grant,
        }
    end
    return out
end

function ShopLogic.banners(cards: { ProductCard }): { ProductCard }
    local list: { ProductCard } = {}
    for _, c in cards do
        if c.kind == "banner" then
            table.insert(list, c)
        end
    end
    return list
end

function ShopLogic.packs(cards: { ProductCard }): { ProductCard }
    local list: { ProductCard } = {}
    for _, c in cards do
        if c.kind == "pack" then
            table.insert(list, c)
        end
    end
    return list
end

return ShopLogic
