--!strict
-- Pure attention gates / apply. CI-tested.

local ExhibitCatalog
if script and script.Parent then
    ExhibitCatalog = require(script.Parent.Parent.data.ExhibitCatalog)
else
    ExhibitCatalog = require("../data/ExhibitCatalog")
end

local AttentionLogic = {}

function AttentionLogic.reactAmount(): number
    return ExhibitCatalog.REACT_ATTENTION
end

function AttentionLogic.cooldownSec(): number
    return ExhibitCatalog.REACT_COOLDOWN_SEC
end

function AttentionLogic.applyReact(current: number): number
    return math.min(current + AttentionLogic.reactAmount(), 100)
end

function AttentionLogic.npcDrip(current: number, npcCount: number, dt: number): number
    if npcCount <= 0 or dt <= 0 then
        return current
    end
    local add = npcCount * 0.15 * dt
    return math.min(current + add, 100)
end

return AttentionLogic
