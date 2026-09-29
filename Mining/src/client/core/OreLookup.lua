--!strict
-- OreLookup.lua — клиентский O(1) доступ к данным руд.
-- Источник правды — shared/data/OreDatabase. Один раз при загрузке модуля
-- строит плоскую { [oreId] = OreDef } мапу, дальше все геттеры — за O(1).
--
-- Этот модуль — единственный путь к данным руд на клиенте. Никаких
-- хардкод-таблиц цветов/редкостей/иконок в рендере или HUD.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("shared")

local Constants = require(shared.constants)
local OreDatabase = require(shared.data.OreDatabase)
local OreAssets = require(shared.data.OreAssets)
local OreTypes = require(shared.types.OreTypes)
local Localization = require(shared.loc.Localization)

type OreDef = OreTypes.OreDef

local OreLookup = {}

local DEFAULT_COLOR = Color3.fromRGB(140, 140, 150)
local DEFAULT_RARITY = "common"
local DEFAULT_ICON = "?"

local _byId: { [string]: OreDef } = {}

local function buildIndex()
    local db = OreDatabase.new()
    for _, pool in pairs(db:getAll()) do
        for _, ore in ipairs(pool) do
            _byId[ore.id] = ore
        end
    end
end

buildIndex()

function OreLookup.getDef(oreId: string): OreDef?
    return _byId[oreId]
end

function OreLookup.getColor(oreId: string): Color3
    local d = _byId[oreId]
    if d and d.color then
        return d.color
    end
    return DEFAULT_COLOR
end

function OreLookup.getRarity(oreId: string): string
    local d = _byId[oreId]
    if d and d.rarity then
        return d.rarity
    end
    return DEFAULT_RARITY
end

function OreLookup.getIcon(oreId: string): string
    local d = _byId[oreId]
    if d and d.icon and d.icon ~= "" and not string.find(d.icon, "rbxassetid://", 1, true) then
        return d.icon
    end
    return DEFAULT_ICON
end

function OreLookup.getImage(oreId: string): string
    return OreAssets.image(oreId)
end

-- Имя руды — локализованное. Единый чокпоинт клиента: журнал/инвентарь/
-- world-подписи зовут getName и получают строку в языке сессии. Ключ строится
-- из стабильного id (ore.{id}.name); при отсутствии ключа — падаем на literal
-- name из БД, затем на сам id.
function OreLookup.getName(oreId: string): string
    local key = "ore." .. oreId .. ".name"
    if Localization.has(key) then
        return Localization.t(key)
    end
    local d = _byId[oreId]
    if d and d.name then
        return d.name
    end
    return oreId
end

function OreLookup.getRarityColor(oreId: string): Color3
    local rarity = OreLookup.getRarity(oreId)
    return Constants.RARITY_COLORS[rarity] or Constants.RARITY_COLORS.common
end

return OreLookup
