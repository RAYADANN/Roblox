--!strict
-- Toybox Premium palette shared by React UI and lightweight world UI.

local Surface = {
	canvas = Color3.fromRGB(255, 244, 220),
	base = Color3.fromRGB(255, 251, 238),
	raised = Color3.fromRGB(255, 255, 250),
	sunken = Color3.fromRGB(241, 222, 188),
	tinted = Color3.fromRGB(255, 235, 194),
	overlay = Color3.fromRGB(46, 34, 52),
}

local Content = {
	primary = Color3.fromRGB(63, 45, 54),
	secondary = Color3.fromRGB(113, 84, 83),
	muted = Color3.fromRGB(151, 121, 112),
	inverse = Color3.fromRGB(255, 254, 246),
	disabled = Color3.fromRGB(183, 160, 148),
}

local Action = {
	primary = Color3.fromRGB(72, 126, 255),
	primaryHighlight = Color3.fromRGB(116, 164, 255),
	primaryShadow = Color3.fromRGB(38, 73, 181),
	collect = Color3.fromRGB(43, 190, 112),
	collectHighlight = Color3.fromRGB(89, 224, 147),
	collectShadow = Color3.fromRGB(18, 118, 72),
	reward = Color3.fromRGB(255, 196, 45),
	rewardHighlight = Color3.fromRGB(255, 225, 105),
	rewardShadow = Color3.fromRGB(190, 120, 24),
	breed = Color3.fromRGB(177, 93, 238),
	breedHighlight = Color3.fromRGB(209, 137, 255),
	breedShadow = Color3.fromRGB(105, 46, 164),
	danger = Color3.fromRGB(238, 76, 92),
	dangerHighlight = Color3.fromRGB(255, 121, 129),
	dangerShadow = Color3.fromRGB(157, 37, 55),
	neutral = Color3.fromRGB(132, 108, 105),
	neutralHighlight = Color3.fromRGB(175, 150, 140),
	neutralShadow = Color3.fromRGB(82, 61, 65),
}

local Border = {
	light = Color3.fromRGB(255, 255, 249),
	soft = Color3.fromRGB(225, 196, 164),
	strong = Color3.fromRGB(91, 61, 70),
	focus = Action.primary,
}

local Semantic = {
	success = Action.collect,
	warning = Color3.fromRGB(255, 164, 48),
	danger = Action.danger,
	info = Action.primary,
	locked = Color3.fromRGB(126, 111, 132),
}

-- Flat aliases are intentionally retained for existing screens and WorldUi.
local ThemeColors = {
	bg1 = Surface.canvas,
	bg2 = Surface.base,
	bg3 = Surface.raised,
	bg4 = Surface.tinted,
	bgChip = Surface.raised,
	dockBg = Surface.base,
	dockBorder = Border.soft,
	panelBg = Surface.base,
	panelBody = Surface.raised,
	panelHeader = Surface.tinted,
	overlay = Surface.overlay,
	veil = Surface.overlay,

	primary = Action.primary,
	primaryHi = Action.primaryHighlight,
	primaryPressed = Action.primaryShadow,
	jade = Action.collect,
	jadeHi = Action.collectHighlight,
	gold = Action.reward,
	goldHi = Action.rewardHighlight,
	goldDeep = Action.rewardShadow,
	sell = Action.collect,
	sellHi = Action.collectHighlight,

	textMain = Content.primary,
	textSub = Content.secondary,
	textMuted = Content.muted,
	textDark = Content.primary,
	white = Content.inverse,

	outline = Border.light,
	outlineSoft = Border.soft,
	outlineDark = Border.strong,
	focus = Border.focus,

	btnBg = Action.neutral,
	btnGold = Action.reward,
	btnDanger = Action.danger,
	btnGhost = Surface.tinted,
	btnJade = Action.collect,

	success = Semantic.success,
	warning = Semantic.warning,
	danger = Semantic.danger,
	error = Semantic.danger,
	info = Semantic.info,

	dirt = Color3.fromRGB(184, 125, 74),
	spikes = Action.danger,
	breed = Action.breed,

	cream = Surface.base,
	creamHi = Surface.raised,
	ink = Content.primary,
	inkSoft = Content.secondary,
	bronze = Color3.fromRGB(166, 113, 72),
	sky = Action.primary,
}

local ThemeRarity = {
	common = Color3.fromRGB(145, 135, 132),
	uncommon = Color3.fromRGB(43, 190, 112),
	rare = Color3.fromRGB(72, 126, 255),
	epic = Color3.fromRGB(177, 93, 238),
	mythic = Color3.fromRGB(255, 177, 35),
	secret = Color3.fromRGB(238, 76, 92),
}

return {
	Colors = ThemeColors,
	Rarity = ThemeRarity,
	Surface = Surface,
	Content = Content,
	Action = Action,
	Border = Border,
	Semantic = Semantic,
}
