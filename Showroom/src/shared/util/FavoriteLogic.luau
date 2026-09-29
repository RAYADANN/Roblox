--!strict
-- Pure favorite-stand helpers. CI-tested.

local Constants
if script and script.Parent then
    Constants = require(script.Parent.Parent.data.Constants)
else
    Constants = require("../data/Constants")
end

local FavoriteLogic = {}

function FavoriteLogic.slotCount(): number
    return Constants.FAVORITE_SLOT_COUNT
end

function FavoriteLogic.isValidSlot(slotIndex: number): boolean
    return slotIndex == math.floor(slotIndex)
        and slotIndex >= 1
        and slotIndex <= Constants.FAVORITE_SLOT_COUNT
end

function FavoriteLogic.firstEmpty(slots: { any? }): number?
    for i = 1, Constants.FAVORITE_SLOT_COUNT do
        if slots[i] == nil then
            return i
        end
    end
    return nil
end

return FavoriteLogic
