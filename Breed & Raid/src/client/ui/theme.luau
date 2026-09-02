--!strict
-- Toybox Premium design tokens. Shared color aliases keep legacy screens compiling.

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

local Radius = {
	xs = UDim.new(0, 8),
	sm = UDim.new(0, 12),
	md = UDim.new(0, 18),
	lg = UDim.new(0, 24),
	xl = UDim.new(0, 28),
	panel = UDim.new(0, 24),
	chip = UDim.new(0, 18),
	btn = UDim.new(0, 18),
	navBtn = UDim.new(0, 22),
	badge = UDim.new(0, 12),
	pill = UDim.new(1, 0),
}

local Stroke = {
	thin = 2,
	medium = 3,
	thick = 4,
	ornate = 4,
	accentBar = 5,
}

local Icon = {
	tint = Colors.textMain,
	inverseTint = ThemeColors.Content.inverse,
	inactiveAlpha = 0.45,
	fallback = "?",
}

local Space = {
	xxs = 4,
	xs = 8,
	sm = 12,
	md = 16,
	lg = 24,
	xl = 32,
	xxl = 40,
}

local Elevation = {
	low = 4,
	medium = 7,
	high = 10,
	modal = 14,
}

local Opacity = {
	disabled = 0.45,
	muted = 0.3,
	overlay = 0.32,
	shadow = 0.18,
}

-- Design space @ 1280×720 — use via layout.px / layout.text / layout.gap
local Design = {
	MODAL_W = 480,
	MODAL_H = 520,
	HEADER_H = 64,
	ROW_H = 56,
	DOCK_H = 82,
	DOCK_BTN = 56,
	ICON_SM = 20,
	ICON_MD = 30,
	ICON_LG = 46,
	PAD_SM = 8,
	PAD_MD = 16,
	PAD_LG = 24,
	CHIP_W = 148,
	CHIP_H = 58,
	SUMMON_W = 300,
	SUMMON_H = 400,
	REWARD_W = 360,
	REWARD_H = 440,
	BTN_H = 54,
	NAV_BTN = 76,
	HOTBAR_BTN = 76,
	PROMPT_W = 228,
	PROMPT_H = 76,
	CARD_W = 168,
	CARD_H = 214,
	TOAST_W = 340,
	TOAST_H = 64,
}

local function rarityColor(band: string): Color3
	local key = string.lower(band)
	return Rarity[key] or Rarity.common
end

return {
	Colors = Colors,
	Rarity = Rarity,
	Surface = ThemeColors.Surface,
	Content = ThemeColors.Content,
	Action = ThemeColors.Action,
	Border = ThemeColors.Border,
	Semantic = ThemeColors.Semantic,
	Font = Font,
	Radius = Radius,
	Stroke = Stroke,
	Icon = Icon,
	Space = Space,
	Elevation = Elevation,
	Opacity = Opacity,
	Design = Design,
	rarityColor = rarityColor,
	Preset = {
		name = "toybox_premium",
		family = "Toybox",
		adjectives = { "warm", "chunky", "icon-first", "playful" },
	},
}
