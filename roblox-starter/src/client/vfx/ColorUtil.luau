--!strict
-- Client helper: StyleTokens RGB → Color3.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StyleTokens = require(ReplicatedStorage.shared.vfx.StyleTokens)

local ColorUtil = {}

function ColorUtil.fromRgb(rgb: StyleTokens.Rgb): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

function ColorUtil.token(key: string): Color3
	return ColorUtil.fromRgb(StyleTokens.rgb(key))
end

return ColorUtil
