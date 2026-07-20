--!strict
-- Arcade dark palette for ScreenGui + WorldUi (family A, canon 23).
-- Adjectives: clean · high-contrast · accent-led

local ThemeColors = {
	-- Surfaces (bg1 darkest → bg4 lightest navy)
	bg1 = Color3.fromRGB(8, 10, 18),
	bg2 = Color3.fromRGB(14, 17, 30),
	bg3 = Color3.fromRGB(22, 26, 44),
	bg4 = Color3.fromRGB(30, 36, 58),
	bgChip = Color3.fromRGB(16, 20, 36),
	dockBg = Color3.fromRGB(11, 13, 24),
	dockBorder = Color3.fromRGB(48, 58, 92),

	panelBg = Color3.fromRGB(18, 22, 38),
	panelBody = Color3.fromRGB(22, 26, 44),
	panelHeader = Color3.fromRGB(26, 32, 52),
	overlay = Color3.fromRGB(4, 6, 12),
	veil = Color3.fromRGB(4, 6, 12),

	-- Brand / action (loud accents on dark)
	primary = Color3.fromRGB(55, 95, 200),
	primaryHi = Color3.fromRGB(90, 130, 240),
	primaryPressed = Color3.fromRGB(35, 65, 150),
	-- Collect / success face (AA with white ~4.8:1)
	jade = Color3.fromRGB(28, 130, 85),
	jadeHi = Color3.fromRGB(52, 190, 120),
	gold = Color3.fromRGB(255, 200, 40),
	goldHi = Color3.fromRGB(255, 230, 120),
	goldDeep = Color3.fromRGB(200, 150, 20),

	-- Aliases (Collect = sell)
	sell = Color3.fromRGB(28, 130, 85),
	sellHi = Color3.fromRGB(52, 190, 120),

	-- Text (light on dark)
	textMain = Color3.fromRGB(228, 234, 255),
	textSub = Color3.fromRGB(148, 158, 195),
	-- ~4.54:1 on bg3
	textMuted = Color3.fromRGB(120, 130, 165),
	textDark = Color3.fromRGB(12, 16, 28),
	white = Color3.fromRGB(255, 255, 255),

	-- Borders / focus
	outline = Color3.fromRGB(255, 255, 255),
	outlineSoft = Color3.fromRGB(90, 105, 150),
	outlineDark = Color3.fromRGB(0, 0, 0),
	focus = Color3.fromRGB(90, 130, 240),

	-- Buttons
	btnBg = Color3.fromRGB(36, 42, 68),
	btnGold = Color3.fromRGB(255, 200, 40),
	btnDanger = Color3.fromRGB(180, 50, 50),
	btnGhost = Color3.fromRGB(28, 34, 56),
	btnJade = Color3.fromRGB(28, 130, 85),

	-- Semantic
	success = Color3.fromRGB(40, 160, 100),
	warning = Color3.fromRGB(255, 180, 40),
	danger = Color3.fromRGB(220, 70, 70),
	error = Color3.fromRGB(220, 70, 70),
	info = Color3.fromRGB(55, 95, 200),

	-- Game resources
	dirt = Color3.fromRGB(180, 130, 80),
	spikes = Color3.fromRGB(220, 70, 70),
	breed = Color3.fromRGB(160, 100, 220),

	-- WorldUi aliases (same family — dark cards outdoors)
	cream = Color3.fromRGB(22, 26, 44),
	creamHi = Color3.fromRGB(30, 36, 58),
	ink = Color3.fromRGB(228, 234, 255),
	inkSoft = Color3.fromRGB(148, 158, 195),
	bronze = Color3.fromRGB(90, 105, 150),
	sky = Color3.fromRGB(55, 95, 200),
}

local ThemeRarity = {
	common = Color3.fromRGB(160, 168, 190),
	uncommon = Color3.fromRGB(52, 190, 120),
	rare = Color3.fromRGB(80, 150, 255),
	epic = Color3.fromRGB(180, 100, 255),
	mythic = Color3.fromRGB(255, 180, 40),
	secret = Color3.fromRGB(255, 70, 100),
}

return {
	Colors = ThemeColors,
	Rarity = ThemeRarity,
}
