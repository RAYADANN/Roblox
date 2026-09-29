--!strict
-- Locales.lua — конфигурация языков (единственный источник истины).
--
-- Меняешь набор поддерживаемых языков / язык по умолчанию — только здесь.
-- Модуль не зависит от игры: переносится в любой Roblox-проект как есть.

local Locales = {}

-- Эталонный каталог: каждый ключ ОБЯЗАН существовать в en.
Locales.DEFAULT = "en"

-- Фолбэк для неизвестных языков и пропущенных ключей.
Locales.FALLBACK = "en"

-- Порядок = приоритет в UI выбора языка (если появится).
Locales.SUPPORTED = { "en", "ru", "es", "pt", "de", "fr", "id", "tr" } :: { string }

-- Нормализация Roblox locale id ("en-us", "pt-br", "ru-ru") → внутренний код.
local ALIASES: { [string]: string } = {
	en = "en",
	ru = "ru",
	es = "es",
	pt = "pt",
	de = "de",
	fr = "fr",
	id = "id",
	tr = "tr",
}

local SUPPORTED_SET: { [string]: boolean } = {}
for _, code in ipairs(Locales.SUPPORTED) do
	SUPPORTED_SET[code] = true
end

function Locales.normalize(robloxLocaleId: string?): string
	if typeof(robloxLocaleId) ~= "string" or robloxLocaleId == "" then
		return Locales.DEFAULT
	end
	local lower = string.lower(robloxLocaleId)
	local prefix = string.match(lower, "^([%a]+)") or lower
	local mapped = ALIASES[prefix]
	if mapped and SUPPORTED_SET[mapped] then
		return mapped
	end
	if SUPPORTED_SET[prefix] then
		return prefix
	end
	return Locales.FALLBACK
end

function Locales.isSupported(code: string): boolean
	return SUPPORTED_SET[code] == true
end

return Locales
