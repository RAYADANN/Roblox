--!strict
-- Минимальная локализация. Расширяй по localization.mdc.

local strings: { [string]: string } = {
    ["hud.coins"] = "Coins",
    ["error.no_coins"] = "Not enough coins",
    ["error.max_level"] = "Max level reached",
}

local Localization = {}

function Localization.t(key: string, _params: { [string]: any }?): string
    return strings[key] or key
end

return Localization
