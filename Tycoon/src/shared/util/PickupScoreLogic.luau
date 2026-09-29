--!strict
-- Pure pickup float-score formatting. No Roblox services.

local FormatMoney
local ScoreGradientCatalog

if script and script.Parent then
    FormatMoney = require(script.Parent.FormatMoney)
    ScoreGradientCatalog = require(script.Parent.Parent.data.ScoreGradientCatalog)
else
    FormatMoney = require("./FormatMoney")
    ScoreGradientCatalog = require("../data/ScoreGradientCatalog")
end

export type DropKind = "normal" | "gold" | "shiny" | "diamond" | "lucky"

export type PickupScoreSpec = {
    text: string,
    --- design-space px at 1920×1080; client scales via ViewportLayout
    textSize: number,
    --- catalog id; client applies UIGradient
    gradientId: string,
    isRare: boolean,
}

local SIZE = {
    normal = 63,
    gold = 75,
    shiny = 87,
    diamond = 108,
    lucky = 81,
}

local PickupScoreLogic = {}

function PickupScoreLogic.encode(kind: string, value: number): string
    return `{kind}|{value}`
end

function PickupScoreLogic.decode(payload: string): (string?, number?)
    local kind, valueStr = string.match(payload, "^([^|]+)|(.+)$")
    if kind == nil or valueStr == nil then
        return nil, nil
    end
    local value = tonumber(valueStr)
    if value == nil then
        return nil, nil
    end
    return kind, value
end

--- gradientIndex picks ScoreGradientCatalog.at (wraps). Pass a random index each play.
function PickupScoreLogic.spec(kind: string, value: number, gradientIndex: number): PickupScoreSpec
    local size = SIZE.normal
    local isRare = false
    if kind == "gold" then
        size = SIZE.gold
    elseif kind == "shiny" then
        size = SIZE.shiny
        isRare = true
    elseif kind == "diamond" then
        size = SIZE.diamond
        isRare = true
    elseif kind == "lucky" then
        size = SIZE.lucky
        isRare = true
    end

    local text: string
    if kind == "lucky" then
        text = "Lucky!"
    else
        text = `+{FormatMoney.short(value)}`
    end

    local gradient = ScoreGradientCatalog.at(gradientIndex)

    return {
        text = text,
        textSize = size,
        gradientId = gradient.id,
        isRare = isRare,
    }
end

return PickupScoreLogic
