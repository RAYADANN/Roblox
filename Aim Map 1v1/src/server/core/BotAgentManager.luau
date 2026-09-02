--!strict
-- Server-side duel bot: humanoid move + imperfect aim + USP fire.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local AssetTemplates = require(script.Parent.AssetTemplates)
local BotCombatLogic = require(ReplicatedStorage.shared.util.BotCombatLogic)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local NetTypes = require(ReplicatedStorage.shared.net.NetTypes)
local WorldMuzzle = require(script.Parent.WorldMuzzle)

export type FireBot = (
    model: Model,
    origin: Vector3,
    direction: Vector3
) -> NetTypes.FireWeaponResult

export type Deps = {
    fireBot: FireBot,
    getTargetPlayer: (matchId: string) -> Player?,
    isMatchLive: (matchId: string) -> boolean,
}

export type BotAgentManager = {
    start: (self: BotAgentManager) -> (),
    isBot: (self: BotAgentManager, model: Model) -> boolean,
    getModel: (self: BotAgentManager, matchId: string) -> Model?,
    spawnForMatch: (self: BotAgentManager, matchId: string, spawnCf: CFrame) -> Model,
    resetForRound: (self: BotAgentManager, matchId: string, spawnCf: CFrame) -> (),
    markDead: (self: BotAgentManager, matchId: string) -> (),
    setActive: (self: BotAgentManager, matchId: string, active: boolean) -> (),
    destroyForMatch: (self: BotAgentManager, matchId: string) -> (),
}

type Agent = {
    matchId: string,
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
    active: boolean,
    alive: boolean,
    reactionSec: number,
    acquiredAt: number?,
    lastSeenAt: number?,
    lastKnownPos: Vector3?,
    lastShotAt: number,
    fireCooldownSec: number,
    roundReadyAt: number,
    rngState: number,
}

local BotAgentManager = {}
BotAgentManager.__index = BotAgentManager

local FOLDER_NAME = "DuelBots"

--- Server Idle so Part Shoot sits on the held barrel (client NPC tracks do not replicate here).
local function playWeaponIdle(humanoid: Humanoid)
    local folder = ReplicatedStorage:FindFirstChild("WeaponAnims")
    if not folder then
        return
    end
    local seq = folder:FindFirstChild("Idle")
    if not (seq and seq:IsA("KeyframeSequence")) then
        seq = folder:FindFirstChild("AimIdle")
    end
    if not (seq and seq:IsA("KeyframeSequence")) then
        return
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end
    local ok, content = pcall(function()
        return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
    end)
    if not ok or typeof(content) ~= "string" or content == "" then
        return
    end
    local animation = Instance.new("Animation")
    animation.Name = "Idle"
    animation.AnimationId = content
    local loaded, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    animation:Destroy()
    if not loaded or typeof(track) ~= "Instance" then
        return
    end
    local idle = track :: AnimationTrack
    idle.Looped = true
    idle.Priority = Enum.AnimationPriority.Action
    idle:Play(0.15)
end

local function buildBot(parent: Instance, cframe: CFrame): Model
    assert(AssetTemplates.hasTemplates(), "R15 template required for duel bot")
    local model = AssetTemplates.cloneR15("DuelBot")
    model:SetAttribute(Constants.BOT_ATTRIBUTE, true)
    model:SetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE, true)

    local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.MaxHealth = Constants.BOT_HP
    humanoid.Health = Constants.BOT_HP
    humanoid.WalkSpeed = Constants.BOT_WALK_SPEED
    humanoid.JumpPower = 0
    humanoid.AutoRotate = false
    -- Dead Humanoids cannot be revived by setting Health; we respawn the model instead.
    humanoid.BreakJointsOnDeath = false
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    for _, desc in model:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.Anchored = false
        end
    end

    model.Parent = parent
    model:PivotTo(cframe)
    AssetTemplates.equipUsp(model)
    playWeaponIdle(humanoid)
    return model
end

local function nextRng(agent: Agent): number
    -- Simple LCG so aim jitter is deterministic-ish per agent.
    agent.rngState = (agent.rngState * 1103515245 + 12345) % 2147483648
    return agent.rngState / 2147483648
end

local function aimPart(character: Model): BasePart?
    -- Prefer torso so Medium bot is not a headshot machine.
    for _, name in { "UpperTorso", "Torso", "HumanoidRootPart", "Head" } do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function eyeOrigin(agent: Agent): Vector3
    return agent.root.Position + Vector3.new(0, 1.4, 0)
end

function BotAgentManager.new(deps: Deps): BotAgentManager
    local folder = workspace:FindFirstChild(FOLDER_NAME)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = workspace
    end

    return setmetatable({
        _deps = deps,
        _folder = folder :: Folder,
        _agents = {} :: { [string]: Agent },
        _acc = 0,
        _started = false,
    }, BotAgentManager) :: any
end

function BotAgentManager:start()
    if self._started then
        return
    end
    self._started = true
    local step = 1 / Constants.BOT_TICK_HZ
    RunService.Heartbeat:Connect(function(dt)
        self._acc += dt
        while self._acc >= step do
            self._acc -= step
            self:_tick(step)
        end
    end)
end

function BotAgentManager:isBot(model: Model): boolean
    return model:GetAttribute(Constants.BOT_ATTRIBUTE) == true
end

function BotAgentManager:getModel(matchId: string): Model?
    local agent = self._agents[matchId]
    return if agent then agent.model else nil
end

function BotAgentManager:spawnForMatch(matchId: string, spawnCf: CFrame): Model
    self:destroyForMatch(matchId)
    local model = buildBot(self._folder, spawnCf)
    local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
    local root = model.PrimaryPart :: BasePart

    local agent: Agent = {
        matchId = matchId,
        model = model,
        humanoid = humanoid,
        root = root,
        active = true,
        alive = true,
        reactionSec = BotCombatLogic.rollReaction(function()
            return math.random()
        end),
        acquiredAt = nil,
        lastSeenAt = nil,
        lastKnownPos = nil,
        lastShotAt = -999,
        fireCooldownSec = Constants.BOT_FIRE_COOLDOWN_SEC,
        roundReadyAt = os.clock() + Constants.BOT_ROUND_GRACE_SEC,
        rngState = (os.clock() * 1000 + #matchId * 97) % 2147483648,
    }
    self._agents[matchId] = agent
    return model
end

function BotAgentManager:resetForRound(matchId: string, spawnCf: CFrame)
    -- Always rebuild: a Dead Humanoid cannot be revived reliably.
    self:spawnForMatch(matchId, spawnCf)
end

function BotAgentManager:markDead(matchId: string)
    local agent = self._agents[matchId]
    if not agent then
        return
    end
    agent.alive = false
    agent.active = false
    pcall(function()
        agent.humanoid:Move(Vector3.zero, false)
    end)
    if agent.humanoid.Health > 0 then
        agent.humanoid.Health = 0
    end
    -- Body knock/ragdoll is applied by WeaponFireManager → DeathRagdoll; do not freeze parts.
end

function BotAgentManager:setActive(matchId: string, active: boolean)
    local agent = self._agents[matchId]
    if not agent then
        return
    end
    agent.active = active
    if not active then
        pcall(function()
            agent.humanoid:Move(Vector3.zero, false)
        end)
    end
end

function BotAgentManager:destroyForMatch(matchId: string)
    local agent = self._agents[matchId]
    if not agent then
        return
    end
    self._agents[matchId] = nil
    if agent.model.Parent then
        agent.model:Destroy()
    end
end

function BotAgentManager:_hasLos(agent: Agent, targetPart: BasePart): boolean
    local origin = eyeOrigin(agent)
    local target = targetPart.Position
    local delta = target - origin
    if delta.Magnitude < 0.5 then
        return true
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { agent.model }
    local hit = workspace:Raycast(origin, delta, params)
    if not hit then
        return true
    end
    return hit.Instance:IsDescendantOf(targetPart.Parent :: Instance)
end

function BotAgentManager:_tick(_dt: number)
    local now = os.clock()
    for matchId, agent in self._agents do
        if not agent.active or not agent.alive then
            continue
        end
        if agent.humanoid.Health <= 0 then
            agent.alive = false
            agent.humanoid:Move(Vector3.zero, false)
            continue
        end
        if not self._deps.isMatchLive(matchId) then
            agent.humanoid:Move(Vector3.zero, false)
            continue
        end

        local player = self._deps.getTargetPlayer(matchId)
        local character = if player then player.Character else nil
        local targetPart = if character then aimPart(character) else nil
        if not targetPart then
            agent.humanoid:Move(Vector3.zero, false)
            continue
        end

        local hasLos = self:_hasLos(agent, targetPart)
        if hasLos then
            agent.lastSeenAt = now
            agent.lastKnownPos = targetPart.Position
            if agent.acquiredAt == nil then
                agent.acquiredAt = now
                agent.reactionSec = BotCombatLogic.rollReaction(function()
                    return nextRng(agent)
                end)
            end
        else
            local sinceSeen = if agent.lastSeenAt then now - agent.lastSeenAt else 999
            if not BotCombatLogic.rememberTarget(false, sinceSeen) then
                agent.acquiredAt = nil
            end
        end

        local aimPos = agent.lastKnownPos or targetPart.Position
        local botPos = agent.root.Position
        local distance = (Vector3.new(aimPos.X, 0, aimPos.Z) - Vector3.new(botPos.X, 0, botPos.Z)).Magnitude
        local band = BotCombatLogic.moveBand(distance)
        local strafe = BotCombatLogic.strafeSign(now)
        local move = BotCombatLogic.moveDirection(
            BotCombatLogic.vec(botPos.X, botPos.Y, botPos.Z),
            BotCombatLogic.vec(aimPos.X, aimPos.Y, aimPos.Z),
            band,
            strafe
        )
        local moveVec = Vector3.new(move.x, move.y, move.z)
        if moveVec.Magnitude > 0.05 then
            agent.humanoid:Move(moveVec.Unit, false)
        else
            agent.humanoid:Move(Vector3.zero, false)
        end

        -- Smooth look toward aim point (yaw).
        local lookFlat = Vector3.new(aimPos.X - botPos.X, 0, aimPos.Z - botPos.Z)
        if lookFlat.Magnitude > 0.2 then
            local targetCf = CFrame.lookAt(botPos, botPos + lookFlat.Unit)
            agent.root.CFrame = agent.root.CFrame:Lerp(targetCf, Constants.BOT_LOOK_LERP)
        end

        if now < agent.roundReadyAt then
            continue
        end

        local timeSinceAcquired = if agent.acquiredAt then now - agent.acquiredAt else 0
        local timeSinceShot = now - agent.lastShotAt
        if
            BotCombatLogic.canFire(
                hasLos,
                timeSinceAcquired,
                agent.reactionSec,
                timeSinceShot,
                agent.fireCooldownSec
            )
        then
            local muzzle = WorldMuzzle.ofCharacter(agent.model)
            local origin = muzzle or eyeOrigin(agent)
            local errorRad = BotCombatLogic.rollAimError(function()
                return nextRng(agent)
            end)
            local dir = BotCombatLogic.aimWithError(
                BotCombatLogic.vec(origin.X, origin.Y, origin.Z),
                BotCombatLogic.vec(
                    targetPart.Position.X,
                    targetPart.Position.Y,
                    targetPart.Position.Z
                ),
                errorRad,
                function()
                    return nextRng(agent)
                end
            )
            agent.lastShotAt = now
            agent.fireCooldownSec = BotCombatLogic.rollFireCooldown(function()
                return nextRng(agent)
            end)
            self._deps.fireBot(agent.model, origin, Vector3.new(dir.x, dir.y, dir.z))
        end
    end
end

return BotAgentManager
