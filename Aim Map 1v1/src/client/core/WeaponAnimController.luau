--!strict
-- R15 weapon + locomotion. Local player tracks replicate; bots/dummies are
-- played on every client (NPC Animator does not replicate from one client).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local R15LocomotionDatabase = require(ReplicatedStorage.shared.data.R15LocomotionDatabase)
local RigAnimLogic = require(ReplicatedStorage.shared.util.RigAnimLogic)

local WeaponAnimController = {}

local FOLDER_NAME = "WeaponAnims"
local SHOOT_NEAR_STUDS = 18
local IDLE_FADE = 0.15
local LOCO_FADE = 0.15
local SHOOT_FADE_IN = 0.1
local SHOOT_FADE_OUT = 0.14

type Bundle = {
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
    aimIdle: AnimationTrack?,
    shoot: AnimationTrack?,
    locoIdle: AnimationTrack?,
    walk: AnimationTrack?,
    walking: boolean,
    shootGen: number,
}

local _started = false
local _weaponIdleId: string?
local _weaponShootId: string?
local _bundles: { [Model]: Bundle } = {}
local _localModel: Model? = nil

local function registerSequence(seq: KeyframeSequence): string?
    local ok, content = pcall(function()
        return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
    end)
    if not ok or typeof(content) ~= "string" or content == "" then
        Logger.warn("WeaponAnimController", `RegisterKeyframeSequence failed for {seq.Name}`)
        return nil
    end
    return content
end

local function ensureWeaponIds(): ()
    if _weaponIdleId and _weaponShootId then
        return
    end
    local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 8)
    if not folder or not folder:IsA("Folder") then
        Logger.warn("WeaponAnimController", "ReplicatedStorage.WeaponAnims missing")
        return
    end
    -- Prefer Idle (authored hold); fall back to AimIdle.
    local idleSeq = folder:FindFirstChild("Idle")
    if not (idleSeq and idleSeq:IsA("KeyframeSequence")) then
        idleSeq = folder:FindFirstChild("AimIdle")
    end
    -- Prefer Shoot2 (new clip); fall back to Shoot.
    local shootSeq = folder:FindFirstChild("Shoot2")
    if not (shootSeq and shootSeq:IsA("KeyframeSequence")) then
        shootSeq = folder:FindFirstChild("Shoot")
    end
    if idleSeq and idleSeq:IsA("KeyframeSequence") then
        _weaponIdleId = registerSequence(idleSeq)
    else
        Logger.warn("WeaponAnimController", "Idle/AimIdle KeyframeSequence missing")
    end
    if shootSeq and shootSeq:IsA("KeyframeSequence") then
        _weaponShootId = registerSequence(shootSeq)
    else
        Logger.warn("WeaponAnimController", "Shoot2/Shoot KeyframeSequence missing")
    end
end

local function loadId(animator: Animator, animationId: string, name: string): AnimationTrack?
    local animation = Instance.new("Animation")
    animation.Name = name
    animation.AnimationId = animationId
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    animation:Destroy()
    if not ok or typeof(track) ~= "Instance" then
        Logger.warn("WeaponAnimController", `LoadAnimation failed: {name}`)
        return nil
    end
    return track :: AnimationTrack
end

local function unbind(model: Model)
    local bundle = _bundles[model]
    if not bundle then
        return
    end
    _bundles[model] = nil
    if _localModel == model then
        _localModel = nil
    end
    if bundle.aimIdle then
        bundle.aimIdle:Stop(0)
    end
    if bundle.shoot then
        bundle.shoot:Stop(0)
    end
    if bundle.locoIdle then
        bundle.locoIdle:Stop(0)
    end
    if bundle.walk then
        bundle.walk:Stop(0)
    end
end

local function playLoco(bundle: Bundle, walking: boolean)
    if bundle.walking == walking then
        return
    end
    bundle.walking = walking
    local walk = bundle.walk
    local idle = bundle.locoIdle
    if walking then
        if idle then
            idle:Stop(LOCO_FADE)
        end
        if walk and not walk.IsPlaying then
            walk:Play(LOCO_FADE)
        end
    else
        if walk then
            walk:Stop(LOCO_FADE)
        end
        if idle and not idle.IsPlaying then
            idle:Play(LOCO_FADE)
        end
    end
end

local function playShootTrack(bundle: Bundle)
    local shoot = bundle.shoot
    if not shoot then
        return
    end
    bundle.shootGen += 1
    local gen = bundle.shootGen
    shoot:Play(SHOOT_FADE_IN, 1, 1)
    local length = shoot.Length
    if length <= SHOOT_FADE_OUT + 0.02 then
        return
    end
    task.delay(length - SHOOT_FADE_OUT, function()
        if bundle.shootGen ~= gen then
            return
        end
        if shoot.IsPlaying then
            shoot:Stop(SHOOT_FADE_OUT)
        end
    end)
end

local function bindModel(model: Model, isLocalPlayer: boolean)
    if _bundles[model] then
        return
    end
    if model:GetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE) ~= true then
        return
    end
    if model:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
        return
    end

    local humanoid = model:WaitForChild("Humanoid", 5)
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        return
    end
    local root = model:WaitForChild("HumanoidRootPart", 5)
    if not root or not root:IsA("BasePart") then
        return
    end
    if model.Parent == nil then
        return
    end

    local animator = humanoid:WaitForChild("Animator", 5)
    if not animator or not animator:IsA("Animator") then
        Logger.warn("WeaponAnimController", "Animator missing")
        return
    end

    ensureWeaponIds()

    local isDummy = model:GetAttribute(Constants.PRACTICE_DUMMY_ATTRIBUTE) == true
    local isBot = model:GetAttribute(Constants.BOT_ATTRIBUTE) == true
    -- Bot weapon Idle is played on the server so Part Shoot matches the visible hold.
    local aimIdle = if _weaponIdleId
            and not isDummy
            and not isBot
        then loadId(animator, _weaponIdleId, "Idle")
        else nil
    local shoot = if _weaponShootId and not isDummy
        then loadId(animator, _weaponShootId, "Shoot2")
        else nil
    local locoIdle = loadId(animator, R15LocomotionDatabase.IDLE, "LocoIdle")
    local walk = if isDummy then nil else loadId(animator, R15LocomotionDatabase.WALK, "Walk")

    if aimIdle then
        aimIdle.Looped = true
        aimIdle.Priority = Enum.AnimationPriority.Action
        aimIdle:Play(IDLE_FADE)
    end
    if shoot then
        shoot.Looped = false
        shoot.Priority = Enum.AnimationPriority.Action2
    end
    if locoIdle then
        locoIdle.Looped = true
        locoIdle.Priority = Enum.AnimationPriority.Idle
        locoIdle:Play(IDLE_FADE)
    end
    if walk then
        walk.Looped = true
        walk.Priority = Enum.AnimationPriority.Movement
    end

    _bundles[model] = {
        model = model,
        humanoid = humanoid,
        root = root,
        aimIdle = aimIdle,
        shoot = shoot,
        locoIdle = locoIdle,
        walk = walk,
        walking = false,
        shootGen = 0,
    }
    if isLocalPlayer then
        _localModel = model
    end

    model.Destroying:Connect(function()
        unbind(model)
    end)
    model:GetAttributeChangedSignal(Constants.RAGDOLL_ATTRIBUTE):Connect(function()
        if model:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
            unbind(model)
        end
    end)
end

local function spawnBind(model: Model, isLocalPlayer: boolean)
    task.spawn(bindModel, model, isLocalPlayer)
end

local function bindPlayer(player: Player)
    local isLocal = player == Players.LocalPlayer
    -- Remote players: their client plays; tracks replicate. Don't double-play.
    if not isLocal then
        return
    end
    local function onCharacter(character: Model)
        spawnBind(character, true)
    end
    if player.Character then
        onCharacter(player.Character)
    end
    player.CharacterAdded:Connect(onCharacter)
end

local function watchFolder(folder: Instance)
    local function tryNpc(inst: Instance)
        if inst:IsA("Model") and inst:GetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE) == true then
            spawnBind(inst, false)
        end
    end
    for _, child in folder:GetChildren() do
        tryNpc(child)
    end
    folder.ChildAdded:Connect(tryNpc)
end

local function tick()
    for model, bundle in _bundles do
        if model.Parent == nil then
            unbind(model)
            continue
        end
        if bundle.walk == nil then
            continue
        end
        local v = bundle.root.AssemblyLinearVelocity
        local speed = Vector3.new(v.X, 0, v.Z).Magnitude
        playLoco(bundle, RigAnimLogic.shouldWalk(speed, Constants.FOOTSTEP_MIN_SPEED))
    end
end

function WeaponAnimController.playShoot()
    local model = _localModel
    if not model then
        return
    end
    local bundle = _bundles[model]
    if bundle then
        playShootTrack(bundle)
    end
end

function WeaponAnimController.playShootNear(worldPos: Vector3)
    local best: Bundle? = nil
    local bestDist = SHOOT_NEAR_STUDS
    for model, bundle in _bundles do
        if model:GetAttribute(Constants.BOT_ATTRIBUTE) ~= true then
            continue
        end
        if not bundle.shoot then
            continue
        end
        local distance = (bundle.root.Position - worldPos).Magnitude
        if RigAnimLogic.isNear(distance, bestDist) then
            bestDist = distance
            best = bundle
        end
    end
    if best then
        playShootTrack(best)
    end
end

function WeaponAnimController.start()
    if _started then
        return
    end
    _started = true

    task.spawn(ensureWeaponIds)

    bindPlayer(Players.LocalPlayer)

    for _, name in { "DuelBots", "PracticeDummies" } do
        local folder = Workspace:FindFirstChild(name)
        if folder then
            watchFolder(folder)
        end
    end
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "DuelBots" or child.Name == "PracticeDummies" then
            watchFolder(child)
        end
    end)

    RunService.Heartbeat:Connect(tick)
end

return WeaponAnimController
