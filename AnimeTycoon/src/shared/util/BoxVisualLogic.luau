--!strict
-- Pure: stand level → box mesh name (palette pick) + Brainrot display names. CI-tested.

local BoxVisualDatabase
if script and script.Parent then
    BoxVisualDatabase = require(script.Parent.Parent.data.BoxVisualDatabase)
else
    BoxVisualDatabase = require("../data/BoxVisualDatabase")
end

local BoxVisualLogic = {}

function BoxVisualLogic.shapeForStandLevel(standLevel: number): string
    return BoxVisualDatabase.shapeForStandLevel(standLevel)
end

function BoxVisualLogic.standLevelFromLuck(luckLevel: number): number
    return BoxVisualDatabase.standLevelFromLuck(luckLevel)
end

--- Pick a palette model name under GameAssets.Boxes/<shape>.
function BoxVisualLogic.pickBoxModelName(standLevel: number, rng01: number): string
    local shape = BoxVisualDatabase.shapeForStandLevel(standLevel)
    local list = BoxVisualDatabase.palettes(shape)
    if #list == 0 then
        return "Box1"
    end
    local idx = math.floor(math.clamp(rng01, 0, 0.999999) * #list) + 1
    return list[idx]
end

function BoxVisualLogic.formatCaseDisplayName(boxModelName: string, standLevel: number?): string
    return BoxVisualDatabase.formatCaseDisplayName(boxModelName, standLevel)
end

--- @deprecated use standLevelFromLuck — kept for tests / callers.
function BoxVisualLogic.standLevelForOfferIndex(_offerIndex: number): number
    return 1
end

return BoxVisualLogic
