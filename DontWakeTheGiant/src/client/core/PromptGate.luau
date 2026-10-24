--!strict
-- Hide ProximityPrompts on plots the LocalPlayer does not own.
-- The server still rejects the action via PlotOwnership.owns.
-- Call start() after the plot instances exist.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotOwnership = require(ReplicatedStorage.shared.util.PlotOwnership)

export type Deps = {
    getPlots: () -> { Instance },
    ownerAttribute: string?,
}

local PromptGate = {}

local _conns: { RBXScriptConnection } = {}
local _started = false

local function refresh(deps: Deps)
    local player = Players.LocalPlayer
    local localId = if player then player.UserId else 0
    local attribute = deps.ownerAttribute or PlotOwnership.OWNER_ATTRIBUTE
    for _, plot in deps.getPlots() do
        local owner = plot:GetAttribute(attribute)
        local ownerId = if typeof(owner) == "number" then owner else nil
        if not PlotOwnership.owns(ownerId, localId) then
            for _, desc in plot:GetDescendants() do
                if desc:IsA("ProximityPrompt") then
                    desc.Enabled = false
                end
            end
        end
    end
end

function PromptGate.start(deps: Deps)
    if _started then
        return
    end
    _started = true
    local attribute = deps.ownerAttribute or PlotOwnership.OWNER_ATTRIBUTE
    local function update()
        refresh(deps)
    end
    update()
    for _, plot in deps.getPlots() do
        table.insert(_conns, plot:GetAttributeChangedSignal(attribute):Connect(update))
    end
end

function PromptGate.stop()
    for _, conn in _conns do
        conn:Disconnect()
    end
    table.clear(_conns)
    _started = false
end

return PromptGate
