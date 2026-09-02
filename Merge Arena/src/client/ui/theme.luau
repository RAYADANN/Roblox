--!strict
-- Design tokens — единственный источник цветов, шрифтов, радиусов.
-- Canon: docs/gdd/Merge Arena — Canon Lock.md §7 (Bright Tactical Toys)

local Colors = {
	bg1 = Color3.fromRGB(234, 243, 250),
	bg2 = Color3.fromRGB(247, 251, 255),
	bg3 = Color3.fromRGB(255, 255, 255),
	bg4 = Color3.fromRGB(213, 228, 242),
	bgChip = Color3.fromRGB(213, 228, 242),
	dockBg = Color3.fromRGB(255, 255, 255),
	dockBorder = Color3.fromRGB(26, 34, 51),

	arenaSky = Color3.fromRGB(169, 212, 240),
	boardFelt = Color3.fromRGB(220, 236, 200),
	boardLine = Color3.fromRGB(62, 107, 69),

	primary = Color3.fromRGB(61, 124, 255),
	primaryHi = Color3.fromRGB(107, 155, 255),
	coral = Color3.fromRGB(255, 107, 90),
	teal = Color3.fromRGB(43, 184, 166),

	gold = Color3.fromRGB(240, 192, 26),
	goldHi = Color3.fromRGB(255, 224, 102),

	sell = Color3.fromRGB(46, 204, 113),
	sellHi = Color3.fromRGB(70, 220, 140),

	panelBg = Color3.fromRGB(255, 255, 255),
	panelBody = Color3.fromRGB(247, 251, 255),

	textMain = Color3.fromRGB(26, 34, 51),
	textSub = Color3.fromRGB(90, 107, 132),
	textMuted = Color3.fromRGB(139, 155, 179),
	white = Color3.fromRGB(255, 255, 255),

	outline = Color3.fromRGB(26, 34, 51),
	outlineDark = Color3.fromRGB(26, 34, 51),

	btnBg = Color3.fromRGB(213, 228, 242),
	tabActive = Color3.fromRGB(255, 255, 255),
	tabInactive = Color3.fromRGB(234, 243, 250),
	tabBorder = Color3.fromRGB(26, 34, 51),

	error = Color3.fromRGB(255, 77, 94),
	success = Color3.fromRGB(46, 204, 113),
}

local Rarity = {
	common = Color3.fromRGB(154, 163, 181),
	uncommon = Color3.fromRGB(43, 184, 166),
	rare = Color3.fromRGB(61, 124, 255),
	epic = Color3.fromRGB(177, 92, 255),
	legendary = Color3.fromRGB(240, 192, 26),
	mythic = Color3.fromRGB(255, 79, 163),
}

local Font = {
	title = Enum.Font.GothamBold,
	body = Enum.Font.GothamMedium,
	heavy = Enum.Font.GothamBlack,
}

local Radius = {
	panel = UDim.new(0, 16),
	chip = UDim.new(0, 12),
	btn = UDim.new(0, 14),
	navBtn = UDim.new(0, 14),
	pill = UDim.new(1, 0),
	board = UDim.new(0, 20),
}

local Stroke = {
	thin = 2,
	medium = 3,
	thick = 4,
}

local Icon = {
	tint = Color3.fromRGB(26, 34, 51),
	inactiveAlpha = 0.45,
}

-- Design-space константы (переводить через layout.px/text)
local Design = {
	MODAL_W = 600,
	MODAL_H = 450,
	HEADER_H = 56,
	ROW_H = 52,
	DOCK_H = 88,
	DOCK_BTN = 56,
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
