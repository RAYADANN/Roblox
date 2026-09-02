--!strict
-- Look sensitivity clamp / defaults (profile + client apply).
-- selene: allow(incorrect_standard_library_use)

local req: any = require
local Constants = if script
    then req(script.Parent.Parent.data.Constants)
    else req("@shared/data/Constants")

local SensitivityLogic = {}

function SensitivityLogic.default(): number
    return Constants.LOOK_SENSITIVITY_DEFAULT
end

function SensitivityLogic.clamp(value: number): number
    return math.clamp(value, Constants.LOOK_SENSITIVITY_MIN, Constants.LOOK_SENSITIVITY_MAX)
end

function SensitivityLogic.isValid(value: number): boolean
    if typeof(value) ~= "number" then
        return false
    end
    if value ~= value then -- NaN
        return false
    end
    return value >= Constants.LOOK_SENSITIVITY_MIN and value <= Constants.LOOK_SENSITIVITY_MAX
end

function SensitivityLogic.round(value: number): number
    return SensitivityLogic.clamp(math.floor(value * 10 + 0.5) / 10)
end

function SensitivityLogic.step(value: number, delta: number): number
    return SensitivityLogic.round(value + delta)
end

function SensitivityLogic.fromRatio(ratio: number): number
    local t = math.clamp(ratio, 0, 1)
    local minV = Constants.LOOK_SENSITIVITY_MIN
    local maxV = Constants.LOOK_SENSITIVITY_MAX
    return SensitivityLogic.round(minV + t * (maxV - minV))
end

function SensitivityLogic.toRatio(value: number): number
    local minV = Constants.LOOK_SENSITIVITY_MIN
    local maxV = Constants.LOOK_SENSITIVITY_MAX
    local clamped = SensitivityLogic.clamp(value)
    return (clamped - minV) / (maxV - minV)
end

return SensitivityLogic
