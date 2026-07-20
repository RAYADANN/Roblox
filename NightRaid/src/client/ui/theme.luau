--!strict
-- Design tokens — единственный источник цветов, шрифтов, радиусов.

local Colors = {
	bg1 = Color3.fromRGB(8, 10, 18),
	bg2 = Color3.fromRGB(14, 17, 30),
	bg3 = Color3.fromRGB(22, 26, 44),
	bg4 = Color3.fromRGB(30, 36, 58),
	bgChip = Color3.fromRGB(16, 20, 36),
	dockBg = Color3.fromRGB(11, 13, 24),
	dockBorder = Color3.fromRGB(38, 46, 74),

	primary = Color3.fromRGB(82, 126, 255),
	primaryHi = Color3.fromRGB(112, 154, 255),

	gold = Color3.fromRGB(255, 212, 38),
	goldHi = Color3.fromRGB(255, 238, 130),

	sell = Color3.fromRGB(44, 210, 108),
	sellHi = Color3.fromRGB(70, 238, 136),

	panelBg = Color3.fromRGB(18, 22, 38),
	panelBody = Color3.fromRGB(22, 26, 44),

	textMain = Color3.fromRGB(228, 234, 255),
	textSub = Color3.fromRGB(148, 158, 195),
	textMuted = Color3.fromRGB(76, 88, 120),
	white = Color3.fromRGB(255, 255, 255),

	outline = Color3.fromRGB(255, 255, 255),
	outlineDark = Color3.fromRGB(0, 0, 0),

	btnBg = Color3.fromRGB(36, 42, 68),
	tabActive = Color3.fromRGB(32, 38, 62),
	tabInactive = Color3.fromRGB(20, 24, 40),
	tabBorder = Color3.fromRGB(50, 58, 88),

	error = Color3.fromRGB(255, 100, 80),
	success = Color3.fromRGB(80, 220, 120),
}

local Rarity = {
	common = Color3.fromRGB(180, 185, 200),
	uncommon = Color3.fromRGB(80, 200, 120),
	rare = Color3.fromRGB(80, 160, 255),
	epic = Color3.fromRGB(180, 100, 255),
	legendary = Color3.fromRGB(255, 180, 40),
	mythic = Color3.fromRGB(255, 80, 120),
}

local Font = {
	title = Enum.Font.GothamBold,
	body = Enum.Font.GothamMedium,
	heavy = Enum.Font.GothamBlack,
}

local Radius = {
	panel = UDim.new(0, 14),
	chip = UDim.new(0, 10),
	btn = UDim.new(0, 10),
	navBtn = UDim.new(0, 12),
	pill = UDim.new(1, 0),
}

local Stroke = {
	thin = 1,
	medium = 1.5,
	thick = 2,
}

local Icon = {
	tint = Color3.fromRGB(255, 255, 255),
	inactiveAlpha = 0.45,
}

-- Design-space константы (переводить через layout.px/text)
local Design = {
	MODAL_W = 600,
	MODAL_H = 450,
	HEADER_H = 56,
	ROW_H = 52,
	DOCK_H = 72,
	DOCK_BTN = 52,
	ICON_SM = 24,
	ICON_MD = 32,
	ICON_LG = 48,
	PAD_SM = 8,
	PAD_MD = 12,
	PAD_LG = 16,
}

return {
	Colors = Colors,
	Rarity = Rarity,
	Font = Font,
	Radius = Radius,
	Stroke = Stroke,
	Icon = Icon,
	Design = Design,
}
