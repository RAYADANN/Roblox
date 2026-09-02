--!strict
-- One place for icon names. Image assets can replace glyph fallbacks without touching components.

export type IconDefinition = {
	glyph: string,
	image: string?,
}

local icons: { [string]: IconDefinition } = {
	close = { glyph = "×" },
	back = { glyph = "‹" },
	forward = { glyph = "›" },
	check = { glyph = "✓" },
	locked = { glyph = "◆" },
	info = { glyph = "i" },
	warning = { glyph = "!" },
	cash = { glyph = "$" },
	collect = { glyph = "↓" },
	pets = { glyph = "P" },
	breed = { glyph = "♥" },
	egg = { glyph = "◉" },
	build = { glyph = "▦" },
	bat = { glyph = "↗" },
	shop = { glyph = "+" },
	roll = { glyph = "↻" },
	block = { glyph = "■" },
	carry = { glyph = "↑" },
	settings = { glyph = "⚙" },
	empty = { glyph = "◇" },
	sparkle = { glyph = "✦" },
}

local fallback: IconDefinition = { glyph = "?" }

local IconRegistry = {}

function IconRegistry.get(name: string): IconDefinition
	return icons[string.lower(name)] or fallback
end

function IconRegistry.has(name: string): boolean
	return icons[string.lower(name)] ~= nil
end

return IconRegistry
