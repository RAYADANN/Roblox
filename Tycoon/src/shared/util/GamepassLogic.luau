--!strict
-- World-pad gamepasses: Auto Collect / X2. CI-tested (Lune).

local ProductIds
if script and script.Parent then
    ProductIds = require(script.Parent.Parent.data.ProductIds)
else
    ProductIds = require("../data/ProductIds")
end

export type Field = "autoCollectEggs" | "autoCollectCash" | "doubleItems"

export type Pass = {
    field: Field,
    gamepassId: number,
    robux: number,
}

local GamepassLogic = {}

-- Hub list: X2 Items, Auto Collect Items, Auto Collect Items (cash pad).
local PASSES: { Pass } = {
    { field = "doubleItems", gamepassId = ProductIds.X2Items, robux = 149 },
    { field = "autoCollectEggs", gamepassId = ProductIds.AutoCollectItems, robux = 149 },
    { field = "autoCollectCash", gamepassId = ProductIds.AutoCollectCash, robux = 149 },
}

function GamepassLogic.passes(): { Pass }
    return PASSES
end

function GamepassLogic.passForField(field: Field): Pass?
    for i = 1, #PASSES do
        if PASSES[i].field == field then
            return PASSES[i]
        end
    end
    return nil
end

function GamepassLogic.passForGamepassId(gamepassId: number): Pass?
    for i = 1, #PASSES do
        if PASSES[i].gamepassId == gamepassId then
            return PASSES[i]
        end
    end
    return nil
end

function GamepassLogic.fieldForAction(action: string): Field?
    if action == "AutoCollectEggs" then
        return "autoCollectEggs"
    elseif action == "AutoCollectCash" then
        return "autoCollectCash"
    elseif action == "DoubleItems" then
        return "doubleItems"
    end
    return nil
end

return GamepassLogic
