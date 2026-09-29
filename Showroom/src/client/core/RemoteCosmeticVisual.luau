--!strict
-- Подписка на косметику ВСЕХ игроков. Стартуй из init.client после boot.
-- Реальный рендер (Model, follower) — в отдельном *Controller; здесь только binding.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttributeSync = require(ReplicatedStorage.shared.util.PlayerAttributeSync)

export type RenderSlots = (player: Player, slots: { PlayerAttributeSync.Slot }) -> ()
export type ClearSlots = (player: Player) -> ()

export type Deps = {
    onSlots: RenderSlots,
    onClear: ClearSlots,
}

type Binding = {
    attrConn: RBXScriptConnection?,
}

local RemoteCosmeticVisual = {}
RemoteCosmeticVisual.__index = RemoteCosmeticVisual

function RemoteCosmeticVisual.new(deps: Deps)
    local self = setmetatable({
        _deps = deps,
        _bindings = {} :: { [number]: Binding },
        _playerConn = {} :: { RBXScriptConnection },
    }, RemoteCosmeticVisual)
    return self
end

function RemoteCosmeticVisual:_apply(player: Player)
    local slots = PlayerAttributeSync.decode(player:GetAttribute(PlayerAttributeSync.ATTRIBUTE))
    if #slots == 0 then
        self._deps.onClear(player)
    else
        self._deps.onSlots(player, slots)
    end
end

function RemoteCosmeticVisual:_bindPlayer(player: Player)
    if player == Players.LocalPlayer then
        return
    end
    local binding: Binding = {}
    binding.attrConn = player
        :GetAttributeChangedSignal(PlayerAttributeSync.ATTRIBUTE)
        :Connect(function()
            self:_apply(player)
        end)
    self._bindings[player.UserId] = binding
    self:_apply(player)
end

function RemoteCosmeticVisual:_unbindPlayer(player: Player)
    local binding = self._bindings[player.UserId]
    if binding then
        if binding.attrConn then
            binding.attrConn:Disconnect()
        end
        self._bindings[player.UserId] = nil
    end
    self._deps.onClear(player)
end

function RemoteCosmeticVisual:start()
    for _, player in Players:GetPlayers() do
        self:_bindPlayer(player)
    end
    table.insert(
        self._playerConn,
        Players.PlayerAdded:Connect(function(player)
            self:_bindPlayer(player)
        end)
    )
    table.insert(
        self._playerConn,
        Players.PlayerRemoving:Connect(function(player)
            self:_unbindPlayer(player)
        end)
    )
end

function RemoteCosmeticVisual:destroy()
    for _, conn in self._playerConn do
        conn:Disconnect()
    end
    table.clear(self._playerConn)
    for userId in self._bindings do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            self:_unbindPlayer(player)
        end
    end
end

return RemoteCosmeticVisual
