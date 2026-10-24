--!strict
-- Движение игрока: крадущийся шаг, поверхность под ногами, скорость, приземления, античит скорости.
-- Состояние читают NoiseService и GiantService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryLogic = require(ReplicatedStorage.shared.util.CarryLogic)
local GameplayConfig = require(ReplicatedStorage.shared.data.GameplayConfig)
local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)

export type PlayerState = {
    sneaking: boolean,
    carryWeight: number,
    surface: string?,
    floorPart: BasePart?,
    horizontalSpeed: number,
    moving: boolean,
    inZone: boolean,
    ragdolled: boolean,
    lastSafeCFrame: CFrame?,
    overspeedSec: number,
    exemptUntil: number,
}

export type Deps = {
    giant: Model,
    roots: { Instance },
    onLanded: (player: Player) -> (),
    onSpeedViolation: (player: Player) -> (),
}

local MovementService = {}
MovementService.__index = MovementService

function MovementService.new(deps: Deps)
    local self = setmetatable({
        _deps = deps,
        _states = {} :: { [Player]: PlayerState },
        _rayParams = RaycastParams.new(),
    }, MovementService)
    self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Вода без коллизий (русло глубже дна): луч из воды её не видит, проверяем перекрытие у ног.
    local liquids: { Instance } = {}
    for _, sceneRoot in deps.roots do
        for _, inst in sceneRoot:GetDescendants() do
            if inst:IsA("BasePart") and not inst.CanCollide then
                local surface = inst:GetAttribute("Surface")
                if surface == "Water" or surface == "Milk" then
                    table.insert(liquids, inst)
                end
            end
        end
    end
    self._liquidParams = OverlapParams.new()
    self._liquidParams.FilterType = Enum.RaycastFilterType.Include
    self._liquidParams.FilterDescendantsInstances = liquids
    self._hasLiquids = #liquids > 0
    return self
end

function MovementService:get(player: Player): PlayerState?
    return self._states[player]
end

function MovementService:setSneak(player: Player, enabled: boolean)
    local state = self._states[player]
    if state then
        state.sneaking = enabled
        player:SetAttribute("Sneaking", enabled)
    end
end

function MovementService:setCarryWeight(player: Player, weight: number)
    local state = self._states[player]
    if state then
        state.carryWeight = weight
    end
end

function MovementService:setRagdolled(player: Player, ragdolled: boolean)
    local state = self._states[player]
    if state then
        state.ragdolled = ragdolled
        -- Полёт рэгдолла быстрый: античит его не трогает ещё секунду после приземления.
        state.exemptUntil = os.clock()
            + (if ragdolled then 3600 else GameplayConfig.SPEED_CHECK_LIMIT_SEC + 1)
    end
end

-- Сервер сам переносит персонажа (спавн, выталкивание из участка): не считать это читом.
function MovementService:exempt(player: Player, seconds: number)
    local state = self._states[player]
    if state then
        state.exemptUntil = math.max(state.exemptUntil, os.clock() + seconds)
    end
end

local function surfaceOf(part: BasePart, giant: Model): string?
    local surface = part:GetAttribute("Surface")
    if typeof(surface) == "string" then
        return surface
    end
    if part:IsDescendantOf(giant) then
        return "Body"
    end
    return nil
end

function MovementService:_update(player: Player, state: PlayerState, dt: number)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not (humanoid and root) or humanoid.Health <= 0 then
        return
    end

    local velocity = root.AssemblyLinearVelocity
    state.horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
    state.moving = state.horizontalSpeed > GiantConfig.MOVING_MIN_SPEED
    local pos = root.Position
    state.inZone = Vector2.new(pos.X, pos.Z).Magnitude <= GiantConfig.ZONE_RADIUS

    self._rayParams.FilterDescendantsInstances =
        { character, workspace:FindFirstChild("Items") :: Instance }
    local hit = workspace:Raycast(pos, Vector3.new(0, -8, 0), self._rayParams)
    state.floorPart = if hit then hit.Instance :: BasePart else nil
    state.surface = if hit then surfaceOf(hit.Instance :: BasePart, self._deps.giant) else nil
    if self._hasLiquids then
        local wet =
            workspace:GetPartBoundsInRadius(pos - Vector3.new(0, 2.5, 0), 1.5, self._liquidParams)
        if wet[1] then
            state.surface = wet[1]:GetAttribute("Surface") :: string
        end
    end

    local base = if state.sneaking then GameplayConfig.SNEAK_SPEED else GameplayConfig.WALK_SPEED
    local surfaceMult = if state.surface
        then GameplayConfig.SURFACE_SPEED_MULT[state.surface] or 1
        else 1
    local allowed = base
        * CarryLogic.speedMult(state.carryWeight, GameplayConfig.WEIGHT_SPEED_PENALTY)
        * surfaceMult
    if not state.ragdolled then
        humanoid.WalkSpeed = allowed
    end

    -- Античит (GDD 12.3): быстрее 1.5× дольше секунды → откат на прошлую позицию.
    if os.clock() < state.exemptUntil or state.ragdolled then
        state.overspeedSec = 0
        state.lastSafeCFrame = root.CFrame
        return
    end
    if state.horizontalSpeed > GameplayConfig.WALK_SPEED * GameplayConfig.SPEED_CHECK_MULT then
        state.overspeedSec += dt
        if state.overspeedSec >= GameplayConfig.SPEED_CHECK_LIMIT_SEC and state.lastSafeCFrame then
            character:PivotTo(state.lastSafeCFrame)
            state.overspeedSec = 0
            self._deps.onSpeedViolation(player)
        end
    else
        state.overspeedSec = 0
        state.lastSafeCFrame = root.CFrame
    end
end

function MovementService:_bindCharacter(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not humanoid then
        return
    end
    local state = self._states[player]
    if state then
        state.sneaking = false
        state.carryWeight = 0
        state.ragdolled = false
        state.lastSafeCFrame = nil
        player:SetAttribute("Sneaking", false)
    end
    humanoid.StateChanged:Connect(function(_, new)
        local s = self._states[player]
        if new == Enum.HumanoidStateType.Landed and s and s.inZone and not s.ragdolled then
            self._deps.onLanded(player)
        end
    end)
end

function MovementService:start()
    local function onPlayer(player: Player)
        self._states[player] = {
            sneaking = false,
            carryWeight = 0,
            surface = nil,
            floorPart = nil,
            horizontalSpeed = 0,
            moving = false,
            inZone = false,
            ragdolled = false,
            lastSafeCFrame = nil,
            overspeedSec = 0,
            exemptUntil = 0,
        }
        player.CharacterAdded:Connect(function(character)
            self:_bindCharacter(player, character)
        end)
        if player.Character then
            task.spawn(self._bindCharacter, self, player, player.Character)
        end
    end
    Players.PlayerAdded:Connect(onPlayer)
    for _, player in Players:GetPlayers() do
        onPlayer(player)
    end
    Players.PlayerRemoving:Connect(function(player)
        self._states[player] = nil
    end)

    task.spawn(function()
        while true do
            local dt = task.wait(GiantConfig.TICK_SEC)
            for player, state in self._states do
                self:_update(player, state, dt)
            end
        end
    end)
end

return MovementService
