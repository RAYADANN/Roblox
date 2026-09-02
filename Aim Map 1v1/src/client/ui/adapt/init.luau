--!strict
--[[
	UI adaptivity — single entry for the whole game.

	1. DesignRoot → one UIScale fitted to host AbsoluteSize.
	2. Layout is authored once @ 1920×1080 (Scale tokens). Same on every device.
	3. Do NOT fork layout with isPhone / *Phone sizes.
]]

local Config = require(script.Config)
local UiScaler = require(script.UiScaler)

local function px(width: number, height: number?): UDim2
    if height ~= nil then
        return UDim2.fromOffset(width, height)
    end
    return UDim2.fromOffset(width, width)
end

return {
    UiScaler = UiScaler,
    Config = Config,
    DEFAULT = Config.DEFAULT,
    REFERENCE = Config.REFERENCE,
    px = px,
}
