--!strict
-- Starter economy stub — not wired for Aim Map 1v1 (duel-first).
-- Kept so template references remain discoverable; do not boot this in init.server.

local EconomyManager = {}
EconomyManager.__index = EconomyManager

export type Deps = {}

function EconomyManager.new(_deps: Deps)
    return setmetatable({}, EconomyManager)
end

return EconomyManager
