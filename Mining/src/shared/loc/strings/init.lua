--!strict
-- strings/init.lua — авто-агрегация namespace-модулей каталога.
--
-- Каждый дочерний ModuleScript возвращает таблицу вида:
--   { ru = { ["ns.key"] = "текст" }, en = { ["ns.key"] = "text" } }
--
-- Добавил новый namespace-файл (например shop.lua) → он подхватывается
-- автоматически, править этот файл не нужно. Так параллельные правки каталога
-- не конфликтуют: каждый модуль владеет своим namespace.
--
-- Добавить новый ЯЗЫК: добавь его код в Locales.SUPPORTED и положи ключи под
-- этим кодом в нужные namespace-модули (полный эталон — en = { ... }).

type Catalog = { [string]: { [string]: string } }

local merged: Catalog = {}

for _, child in ipairs(script:GetChildren()) do
	if child:IsA("ModuleScript") then
		local ok, ns = pcall(require, child)
		if ok and typeof(ns) == "table" then
			for locale, entries in pairs(ns :: any) do
				if typeof(entries) == "table" then
					local bucket = merged[locale]
					if bucket == nil then
						bucket = {}
						merged[locale] = bucket
					end
					for key, value in pairs(entries) do
						bucket[key] = value
					end
				end
			end
		end
	end
end

return merged
