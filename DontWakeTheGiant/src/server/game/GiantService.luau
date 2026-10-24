--!strict
-- Великан: фазы сна, взгляд, взмахи, WAKE (GDD 2.3, 4.2, 4.3).
-- Публикует Phase / GazeYaw / EyePosition на ReplicatedStorage.GiantState.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GazeLogic = require(ReplicatedStorage.shared.util.GazeLogic)
local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local NoiseLogic = require(ReplicatedStorage.shared.util.NoiseLogic)

local GiantAttacks = require(script.Parent.GiantAttacks)
local GiantRig = require(script.Parent.GiantRig)

export type Deps = {
    state: Configuration,
    scene: any,
    noise: any,
    movement: any,
    carry: any,
    feedAll: (kind: string, text: string) -> (),
}

local GiantService = {}
GiantService.__index = GiantService

function GiantService.new(deps: Deps)
    local rig = GiantRig.new(deps.scene.giant)
    local coverParams = RaycastParams.new()
    coverParams.FilterType = Enum.RaycastFilterType.Include
    coverParams.FilterDescendantsInstances = deps.scene.coverParts
    local self = setmetatable({
        _deps = deps,
        _rig = rig,
        _phase = "Deep" :: NoiseLogic.Phase,
        _gazeT = 0,
        _gazeYaw = 0,
        _exposure = {} :: { [Player]: number },
        _coverParams = coverParams,
        _nextSwatAt = 0,
        _attackToken = 0,
        _waking = false,
    }, GiantService)
    self._attacks = GiantAttacks.new({
        rig = rig,
        fxFolder = deps.scene.fxFolder,
        carry = deps.carry,
        movement = deps.movement,
        isCurrent = function(token: number)
            return self._attackToken == token
        end,
    })
    return self
end

function GiantService:phase(): NoiseLogic.Phase
    return self._phase
end

function GiantService:_setPhase(phase: NoiseLogic.Phase)
    if self._phase == phase then
        return
    end
    self._phase = phase
    self._deps.state:SetAttribute("Phase", phase)
    if phase == "Restless" then
        self._nextSwatAt = os.clock() + GiantConfig.SWAT_INTERVAL_MIN * 0.5
    elseif phase == "EyeOpen" then
        self._gazeT = 0
    end
    if phase ~= "Wake" then
        self._rig.lidL = if phase == "EyeOpen" then 1 else 0
        self._rig.lidR = 0
    end
    Logger.debug("Giant", `phase → {phase}`)
end

-- WAKE: подъём, удары ладонями, зевок (GDD 4.3). teddyThief — Teddy_Rage.
function GiantService:wake(teddyThief: Player?)
    if self._waking then
        return
    end
    self._waking = true
    self._attackToken += 1
    local token = self._attackToken
    local noise = self._deps.noise
    noise:set(GiantConfig.NOISE_MAX)
    noise:setFrozen(true)
    self:_setPhase("Wake")
    self._rig.lidL, self._rig.lidR = 1, 1
    self._deps.feedAll("wake", if teddyThief then "WHERE'S MY TEDDY?!" else "HE'S AWAKE!")

    task.spawn(function()
        self._attacks:wakeSequence(token, teddyThief)
        self._waking = false
        noise:afterWake()
        self:_setPhase(NoiseLogic.phaseFor(noise:get(), "Deep", GiantConfig :: any))
    end)
end

function GiantService:_checkGaze(dt: number)
    local eye = self._rig:eyePosition()
    local watching = self._phase == "EyeOpen"
    for _, player in Players:GetPlayers() do
        local exposure = self._exposure[player] or 0
        local s = self._deps.movement:get(player)
        local head = player.Character and player.Character:FindFirstChild("Head") :: BasePart?
        local seen = false
        if watching and s and head and s.inZone and not s.ragdolled then
            local carried = self._deps.carry:carried(player)
            local target = {
                dx = head.Position.X - eye.X,
                dz = head.Position.Z - eye.Z,
                horizontalSpeed = s.horizontalSpeed,
                sneaking = s.sneaking,
                carryWeight = if carried then carried.def.weight else 0,
            }
            if
                GazeLogic.inCone(self._gazeYaw, target, GiantConfig :: any)
                and GazeLogic.isConspicuous(target, GiantConfig :: any)
            then
                local hit = workspace:Raycast(eye, head.Position - eye, self._coverParams)
                seen = hit == nil
            end
        end
        if seen then
            exposure += dt
        else
            exposure = math.max(0, exposure - dt * GiantConfig.GAZE_DECAY_MULT)
        end
        if exposure >= GiantConfig.GAZE_CATCH_SEC then
            exposure = 0
            self._deps.carry:catch(player, "The giant saw you!")
        end
        self._exposure[player] = exposure
        local shown = math.floor(exposure / GiantConfig.GAZE_CATCH_SEC * 20 + 0.5) / 20
        if player:GetAttribute("Spotted") ~= shown then
            player:SetAttribute("Spotted", shown)
        end
    end
end

function GiantService:_tick(dt: number)
    if not self._waking then
        local noise = self._deps.noise:get()
        if noise >= GiantConfig.NOISE_MAX then
            self:wake(nil)
        else
            self:_setPhase(NoiseLogic.phaseFor(noise, self._phase, GiantConfig :: any))
        end
    end
    if
        self._phase == "Restless"
        and not self._attacks:busy()
        and os.clock() >= self._nextSwatAt
    then
        self._nextSwatAt = os.clock()
            + GiantConfig.SWAT_INTERVAL_MIN
            + math.random() * (GiantConfig.SWAT_INTERVAL_MAX - GiantConfig.SWAT_INTERVAL_MIN)
        local token = self._attackToken
        task.spawn(function()
            self._attacks:swat(token)
        end)
    end
    self:_checkGaze(dt)
end

function GiantService:start()
    local state = self._deps.state
    state:SetAttribute("Phase", self._phase)
    state:SetAttribute("GazeYaw", 0)
    Players.PlayerRemoving:Connect(function(player)
        self._exposure[player] = nil
    end)
    RunService.Heartbeat:Connect(function(dt)
        if self._phase == "EyeOpen" then
            self._gazeT += dt
            self._gazeYaw = GazeLogic.yawAt(self._gazeT, GiantConfig :: any)
        end
        self._rig.gazeYaw = self._gazeYaw
        self._rig.gazeVisible = self._phase == "EyeOpen"
        self._rig:step(dt)
    end)
    task.spawn(function()
        while true do
            local dt = task.wait(GiantConfig.TICK_SEC)
            self:_tick(dt)
            state:SetAttribute("GazeYaw", math.floor(self._gazeYaw * 10 + 0.5) / 10)
            state:SetAttribute("EyePosition", self._rig:eyePosition())
        end
    end)
end

return GiantService
