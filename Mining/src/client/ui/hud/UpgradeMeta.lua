--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local L = require(ReplicatedStorage:WaitForChild("shared").loc.Localization).t

local UpgradeMeta = {
    NAME_KEYS = {
        pickaxe = "component.upg.name.pickaxe",
        speed = "component.upg.name.speed",
        fortune = "component.upg.name.fortune",
        inventory = "component.upg.name.inventory",
        crit = "component.upg.name.crit",
        multiSell = "component.upg.name.multiSell",
    },
    DESC_KEYS = {
        pickaxe = "component.upg.desc.pickaxe",
        speed = "component.upg.desc.speed",
        fortune = "component.upg.desc.fortune",
        inventory = "component.upg.desc.inventory",
        crit = "component.upg.desc.crit",
        multiSell = "component.upg.desc.multiSell",
    },
    ORDER = { "pickaxe", "speed", "fortune", "inventory", "crit", "multiSell" },
}

function UpgradeMeta.name(id: string): string
    local key = UpgradeMeta.NAME_KEYS[id]
    return if key then L(key) else id
end

function UpgradeMeta.desc(id: string): string
    local key = UpgradeMeta.DESC_KEYS[id]
    return if key then L(key) else ""
end

-- Back-compat: старые потребители читают NAMES/DESC как резолвленные строки.
UpgradeMeta.NAMES = setmetatable({} :: { [string]: string }, {
    __index = function(_, id: string): string
        return UpgradeMeta.name(id)
    end,
})
UpgradeMeta.DESC = setmetatable({} :: { [string]: string }, {
    __index = function(_, id: string): string
        return UpgradeMeta.desc(id)
    end,
})

return UpgradeMeta
