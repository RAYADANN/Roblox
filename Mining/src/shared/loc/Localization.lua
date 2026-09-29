--!strict
-- Localization.lua — key-based i18n движок (переносимый, без зависимостей от игры).
--
-- Зачем свой обёртка, а не авто-захват текста Roblox:
--   * в игре есть композитные/динамические строки (цены, глубина, счётчики) —
--     их нельзя переводить по фрагментам, только через параметры формата;
--   * каталог строк живёт в коде как единственный источник истины (git-diff,
--     ревью, перенос в другой проект) — не зависит от облачной LocalizationTable
--     и настроек Creator Hub.
--
-- Определение языка:
--   * клиент — Player.LocaleId (язык аккаунта / in-experience setting);
--     RobloxLocaleId — только core UI Roblox и часто остаётся en-us для ru и др.;
--   * сервер — RobloxLocaleId (world-space теги без per-viewer локализации).
--   initClient() вызывать до первого L(); слушает смену языка в сессии.
--
-- Цепочка фолбэков: запрошенный язык → FALLBACK (полный каталог) → сам ключ.
-- Пустую строку не возвращаем никогда.
--
-- API:
--   Localization.t(key, params?) -> string        -- основной резолвер
--   Localization.getLocale() -> string            -- текущий язык сессии
--   Localization.setLocale(code)                  -- override (тест/настройка)
--   Localization.initClient(player)               -- клиент: детект + смена языка
--   Localization.onLocaleChanged(fn) -> unsubscribe
--   Localization.has(key) -> boolean

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Locales = require(script.Parent.Locales)
local Catalog = require(script.Parent.strings)
local NumberFormat = require(script.Parent.Parent.util.NumberFormat)

type StringTable = { [string]: string }
type Params = { [any]: any }

local Localization = {}

local _locale: string? = nil
local _warned: { [string]: boolean } = {}
local _listeners: { [(string) -> ()]: boolean } = {}

-- ── Определение языка ──────────────────────────────────────────────────────────
local function detectLocale(): string
	if RunService:IsClient() then
		local player = Players.LocalPlayer
		if player then
			local playerLocale = player.LocaleId
			if typeof(playerLocale) == "string" and playerLocale ~= "" then
				return Locales.normalize(playerLocale)
			end
		end
	end

	local raw: string? = nil
	local ok = pcall(function()
		raw = LocalizationService.RobloxLocaleId
	end)
	if not ok or raw == nil or raw == "" then
		return Locales.DEFAULT
	end
	return Locales.normalize(raw)
end

function Localization.getLocale(): string
	if _locale == nil then
		_locale = detectLocale()
	end
	return _locale :: string
end

-- Принудительно выставить язык (для тестов/настройки игрока). Уведомляет
-- подписчиков, чтобы реактивный UI мог перерисоваться.
function Localization.setLocale(code: string): ()
	local normalized = Locales.normalize(code)
	if normalized == _locale then
		return
	end
	_locale = normalized
	for fn in pairs(_listeners) do
		task.spawn(fn, normalized)
	end
end

function Localization.onLocaleChanged(fn: (string) -> ()): () -> ()
	_listeners[fn] = true
	return function()
		_listeners[fn] = nil
	end
end

-- Клиент: резолвим язык до первого L() (модули вроде TutorialFlow пекут строки
-- при require). Слушаем Player.LocaleId и Translator.LocaleId на смену в сессии.
function Localization.initClient(player: Player): ()
	if not RunService:IsClient() then
		return
	end

	local function applyRawLocale(raw: string?)
		if typeof(raw) ~= "string" or raw == "" then
			return
		end
		Localization.setLocale(raw)
	end

	applyRawLocale(player.LocaleId)

	player:GetPropertyChangedSignal("LocaleId"):Connect(function()
		applyRawLocale(player.LocaleId)
	end)

	task.spawn(function()
		local ok, translator = pcall(function()
			return LocalizationService:GetTranslatorForPlayerAsync(player)
		end)
		if ok and translator then
			translator:GetPropertyChangedSignal("LocaleId"):Connect(function()
				applyRawLocale(translator.LocaleId)
			end)
		end
	end)
end

-- ── Интерполяция параметров ─────────────────────────────────────────────────────
-- Поддерживает {1}/{2} (позиционные) и {name} (именованные). Пропущенный
-- параметр остаётся как {token} — заметно при отладке, но не ломает верстку.
local function interpolate(template: string, params: Params?): string
	if params == nil then
		return template
	end
	local result = string.gsub(template, "{([%w_]+)}", function(token: string): string
		local value = params[token]
		if value == nil then
			local index = tonumber(token)
			if index ~= nil then
				value = params[index]
			end
		end
		if value == nil then
			return "{" .. token .. "}"
		end
		if typeof(value) == "number" then
			return NumberFormat.decimal(value, 1)
		end
		return tostring(value)
	end)
	return result
end

-- ── Резолвер ────────────────────────────────────────────────────────────────────
local function lookup(locale: string, key: string): string?
	local table_ = Catalog[locale]
	if table_ == nil then
		return nil
	end
	return table_[key]
end

-- t(key, params?) — вернуть переведённую строку.
--   L("shop.title")                       -> "МАГАЗИН"
--   L("shop.buyFor", { price = 500 })     -> "Купить за 500"
--   L("pets.owned", { 3, 12 })            -> "У вас 3 из 12"
function Localization.t(key: string, params: Params?): string
	local locale = Localization.getLocale()

	local template = lookup(locale, key)
	if template == nil and locale ~= Locales.FALLBACK then
		template = lookup(Locales.FALLBACK, key)
	end

	if template == nil then
		if not _warned[key] then
			_warned[key] = true
			warn(string.format("[Localization] missing key: %q (locale=%s)", key, locale))
		end
		return key
	end

	return interpolate(template, params)
end

function Localization.has(key: string): boolean
	local locale = Localization.getLocale()
	return lookup(locale, key) ~= nil or lookup(Locales.FALLBACK, key) ~= nil
end

return Localization
