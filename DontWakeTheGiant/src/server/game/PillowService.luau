--!strict
-- Подушка (GDD 2.1): у всех, удар выбивает предмет и даёт лёгкий рэгдолл 0.8 с, перезарядка 2 с.
-- Удар в сокровищнице шумит +6.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.shared.data.GameplayConfig)
local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)

export type Deps = {
    carry: any,
    noise: any,
    movement: any,
}

local PillowService = {}
PillowService.__index = PillowService

function PillowService.new(deps: Deps)
    return setmetatable({ _deps = deps, _readyAt = {} :: { [Player]: number } }, PillowService)
end

local function makeTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "Pillow"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.ToolTip = "Bonk!"
    tool.GripPos = Vector3.new(0, -0.5, 0)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(2, 0.8, 3)
    handle.Color = Color3.fromHex("#F2F3F3")
    handle.Material = Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool
    return tool
end

function PillowService:_swing(player: Player)
    local now = os.clock()
    if now < (self._readyAt[player] or 0) then
        return
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local state = self._deps.movement:get(player)
    if not root or not state or state.ragdolled then
        return
    end
    self._readyAt[player] = now + GameplayConfig.PILLOW_COOLDOWN_SEC

    if state.inZone then
        self._deps.noise:add(GiantConfig.PILLOW_NOISE, root.Position)
    end
    local look = root.CFrame.LookVector
    local cosLimit = math.cos(math.rad(GameplayConfig.PILLOW_HALF_ANGLE))
    for _, other in Players:GetPlayers() do
        local otherRoot = other ~= player
            and other.Character
            and other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        local otherState = self._deps.movement:get(other)
        if not otherRoot or not otherState or otherState.ragdolled then
            continue
        end
        local offset = otherRoot.Position - root.Position
        local flat = Vector3.new(offset.X, 0, offset.Z)
        if
            flat.Magnitude <= GameplayConfig.PILLOW_RANGE
            and (flat.Magnitude < 1 or flat.Unit:Dot(look) >= cosLimit)
        then
            self._deps.carry:knockOut(other)
            local dir = if flat.Magnitude > 0.1 then flat.Unit else look
            self._deps.carry:ragdoll(
                other,
                GameplayConfig.PILLOW_RAGDOLL_SEC,
                dir * GameplayConfig.PILLOW_PUSH_SPEED + Vector3.new(0, 20, 0)
            )
        end
    end
end

function PillowService:start()
    local function give(player: Player)
        local backpack = player:WaitForChild("Backpack", 10)
        if not backpack or backpack:FindFirstChild("Pillow") then
            return
        end
        local tool = makeTool()
        -- Activated приходит на сервер от клиента-владельца инструмента.
        tool.Activated:Connect(function()
            self:_swing(player)
        end)
        tool.Parent = backpack
    end
    local function onPlayer(player: Player)
        player.CharacterAdded:Connect(function()
            give(player)
        end)
        if player.Character then
            task.spawn(give, player)
        end
    end
    Players.PlayerAdded:Connect(onPlayer)
    for _, player in Players:GetPlayers() do
        onPlayer(player)
    end
    Players.PlayerRemoving:Connect(function(player)
        self._readyAt[player] = nil
    end)
end

return PillowService
