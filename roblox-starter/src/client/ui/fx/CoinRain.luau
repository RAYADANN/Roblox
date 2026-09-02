--!strict
-- Skin of FlyBurst with coin-ish defaults. Swap texture/color per game.

local theme = require(script.Parent.Parent.theme)
local FlyBurst = require(script.Parent.FlyBurst)

export type Options = FlyBurst.FlyBurstOptions

local CoinRain = {}

function CoinRain.play(opts: Options)
	local merged: Options = {
		from = opts.from,
		to = opts.to,
		count = opts.count or 14,
		texture = opts.texture,
		color = opts.color or theme.Colors.gold,
		sizePx = opts.sizePx or 16,
		duration = opts.duration or 0.6,
		spreadPx = opts.spreadPx or 40,
		stagger = opts.stagger or 0.025,
		maxCount = opts.maxCount or 20,
	}
	FlyBurst.play(merged)
end

return CoinRain
