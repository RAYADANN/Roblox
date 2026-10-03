--!strict
-- Locally hide ProximityPrompts on bases the LocalPlayer does not own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local ConveyorVisual = require(script.Parent.ConveyorVisual)

local BasePromptGate = {}

local _conns: { RBXScriptConnection } = {}
local _started = false

local function refresh()
    local player = Players.LocalPlayer
    local localId = if player then player.UserId else 0
    for _, base in BaseLayout.getAll() do
        local owner = BaseLayout.getOwnerUserId(base)
        local mine = owner ~= nil and owner == localId
        if not mine then
            for _, d in base:GetDescendants() do
                if d:IsA("ProximityPrompt") then
                    d.Enabled = false
                    d.MaxActivationDistance = 0
                end
            end
        end
    end
    ConveyorVisual.invalidatePaths()
end

function BasePromptGate.refresh()
    refresh()
end

function BasePromptGate.start()
    if _started then
        return
    end
    _started = true
    refresh()
    for _, base in BaseLayout.getAll() do
        table.insert(
            _conns,
            base:GetAttributeChangedSignal(BaseLayout.ATTR_OWNER_USER_ID):Connect(refresh)
        )
    end
    local player = Players.LocalPlayer
    if player then
        table.insert(
            _conns,
            player:GetAttributeChangedSignal(BaseLayout.PLAYER_ATTR_BASE_NAME):Connect(refresh)
        )
    end
    task.defer(refresh)
    task.delay(1, refresh)
    task.delay(3, refresh)
end

return BasePromptGate
