--!strict
-- Общий шум сервера (GDD 2.2). Считает только сервер, только в зоне, тик 0.1 с.
-- Значение публикуется атрибутом Noise на ReplicatedStorage.GiantState.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)
local ItemsConfig = require(ReplicatedStorage.shared.data.ItemsConfig)
local NoiseLogic = require(ReplicatedStorage.shared.util.NoiseLogic)

type MovementService = { get: (any, Player) -> any }

export type Deps = {
    state: Configuration,
    movement: MovementService,
}

local NoiseService = {}
NoiseService.__index = NoiseService

function NoiseService.new(deps: Deps)
    return setmetatable({
        _deps = deps,
        _noise = 0,
        _published = -1,
        _frozen = false,
        _calmUntil = 0,
        _lastWakeAt = os.clock(),
    }, NoiseService)
end

function NoiseService:get(): number
    return self._noise
end

function NoiseService:inZone(position: Vector3): boolean
    return Vector2.new(position.X, position.Z).Magnitude <= GiantConfig.ZONE_RADIUS
end

function NoiseService:_mult(): number
    return if os.clock() < self._calmUntil then GiantConfig.AFTER_WAKE_NOISE_MULT else 1
end

-- Разовый шум. position: шум вне зоны сокровищницы не считается.
function NoiseService:add(amount: number, position: Vector3?)
    if self._frozen or (position and not self:inZone(position)) then
        return
    end
    self._noise = NoiseLogic.apply(self._noise, amount * self:_mult(), GiantConfig.NOISE_MAX)
    self:_publish(false)
end

function NoiseService:set(value: number)
    self._noise = math.clamp(value, 0, GiantConfig.NOISE_MAX)
    self:_publish(true)
end

-- Во время WAKE шум не копится и не затухает.
function NoiseService:setFrozen(frozen: boolean)
    self._frozen = frozen
end

-- После пробуждения: шум 25 и 20 с «глубокого сна» (GDD 2.3).
function NoiseService:afterWake()
    self._lastWakeAt = os.clock()
    self._calmUntil = os.clock() + GiantConfig.AFTER_WAKE_CALM_SEC
    self._frozen = false
    self:set(GiantConfig.AFTER_WAKE_NOISE)
    self._deps.state:SetAttribute(
        "CalmUntil",
        workspace:GetServerTimeNow() + GiantConfig.AFTER_WAKE_CALM_SEC
    )
end

function NoiseService:_publish(force: boolean)
    if
        force
        or math.abs(self._noise - self._published) >= GiantConfig.NOISE_REPLICATE_STEP
        or (self._noise == 0 and self._published ~= 0)
    then
        self._published = self._noise
        self._deps.state:SetAttribute("Noise", math.floor(self._noise * 10 + 0.5) / 10)
    end
end

function NoiseService:_tick(dt: number)
    if self._frozen then
        return
    end
    local rate = 0
    for _, player in Players:GetPlayers() do
        local s = self._deps.movement:get(player)
        if s and s.inZone and not s.ragdolled then
            rate += NoiseLogic.stepRate({
                moving = s.moving,
                sneaking = s.sneaking,
                carryWeight = s.carryWeight,
                surface = s.surface,
                bootsMult = 1,
            }, GiantConfig :: any, ItemsConfig.CARRY_NOISE_MULT)
        end
    end
    local decay = NoiseLogic.decayRate(os.clock() - self._lastWakeAt, GiantConfig :: any)
    self._noise =
        NoiseLogic.apply(self._noise, (rate * self:_mult() - decay) * dt, GiantConfig.NOISE_MAX)
    self:_publish(false)
end

function NoiseService:start()
    self:set(0)
    task.spawn(function()
        while true do
            self:_tick(task.wait(GiantConfig.TICK_SEC))
        end
    end)
end

return NoiseService
