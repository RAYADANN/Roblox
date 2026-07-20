--!strict
-- Arcade dark design tokens (family A + ThemeColors shared).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeColors = require(ReplicatedStorage.shared.ui.ThemeColors)

local Colors = ThemeColors.Colors
local Rarity = ThemeColors.Rarity

local Font = {
	title = Enum.Font.GothamBold,
	body = Enum.Font.GothamMedium,
	heavy = Enum.Font.GothamBlack,
	display = Enum.Font.GothamBlack,
	caption = Enum.Font.GothamMedium,
}

-- 4 / 8 / 12 / 16 — only these corner steps
local Radius = {
	xs = UDim.new(0, 4),
	sm = UDim.new(0, 8),
	md = UDim.new(0, 12),
	lg = UDim.new(0, 16),
	panel = UDim.new(0, 14),
	chip = UDim.new(0, 12),
	btn = UDim.new(0, 10),
	navBtn = UDim.new(0, 10),
	badge = UDim.new(0, 8),
	pill = UDim.new(1, 0),
}

local Stroke = {
	thin = 1,
	medium = 2,
	thick = 2.5,
	ornate = 2,
	accentBar = 3,
}

local Icon = {
	tint = Colors.textMain,
	inactiveAlpha = 0.4,
}

-- Design space @ 1280×720 — use via layout.px / layout.text / layout.gap
local Design = {
	MODAL_W = 400,
	MODAL_H = 460,
	HEADER_H = 44,
	ROW_H = 48,
	DOCK_H = 72,
	DOCK_BTN = 48,
	ICON_SM = 22,
	ICON_MD = 32,
	ICON_LG = 48,
	PAD_SM = 8,
	PAD_MD = 12,
	PAD_LG = 16,
	CHIP_W = 136,
	CHIP_H = 52,
	SUMMON_W = 300,
	SUMMON_H = 400,
	REWARD_W = 360,
	REWARD_H = 440,
	BTN_H = 48,
	NAV_BTN = 72,
	HOTBAR_BTN = 72,
	PROMPT_W = 228,
	PROMPT_H = 76,
}

local function rarityColor(band: string): Color3
	local key = string.lower(band)
	return Rarity[key] or Rarity.common
end

return {
	Colors = Colors,
	Rarity = Rarity,
	Font = Font,
	Radius = Radius,
	Stroke = Stroke,
	Icon = Icon,
	Design = Design,
	rarityColor = rarityColor,
	Preset = {
		name = "arcade_dark",
		family = "A",
		adjectives = { "clean", "high-contrast", "accent-led" },
	},
}
