--!strict
-- Local + remote footsteps. Remotes use distance volume (CombatAudioLogic).
-- Default Roblox body sounds are replaced by src/starter/RbxCharacterSounds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CombatAudioLogic = require(ReplicatedStorage.shared.util.CombatAudioLogic)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local FootstepLogic = require(ReplicatedStorage.shared.util.FootstepLogic)
local SoundManager = require(script.Parent.SoundManager)

local FootstepController = {}

type Tracker = {
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
    accum: number,
    isLocal: boolean,
}

local _started = false
local _trackers: { [Model]: Tracker } = {}
local _conn: RBXScriptConnection? = nil

-- Engine RbxCharacterSounds instances on HumanoidRootPart.
local DEFAULT_BODY_SOUNDS: { [string]: boolean } = {
    Running = true,
    Climbing = true,
    Died = true,
    GettingUp = true,
    Swimming = true,
    Jumping = true,
    Landing = true,
    Splash = true,
    FreeFalling = true,
}

local function stripDefaultBodySound(inst: Instance)
    if inst:IsA("Sound") and DEFAULT_BODY_SOUNDS[inst.Name] then
        inst:Destroy()
    end
end

local function suppressDefaultBodySounds(root: BasePart)
    for _, child in root:GetChildren() do
        stripDefaultBodySound(child)
    end
    root.ChildAdded:Connect(stripDefaultBodySound)
end

local function listenerPosition(): Vector3?
    local cam = Workspace.CurrentCamera
    if cam then
        return cam.CFrame.Position
    end
    local character = Players.LocalPlayer.Character
    if not character then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root.Position
    end
    return nil
end

local function horizontalSpeed(root: BasePart): number
    local v = root.AssemblyLinearVelocity
    return Vector3.new(v.X, 0, v.Z).Magnitude
end

local function isOnGround(humanoid: Humanoid): boolean
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
        return false
    end
    if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Dead then
        return false
    end
    return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function volumeForTracker(tracker: Tracker): number
    if tracker.isLocal then
        return 1
    end
    local listener = listenerPosition()
    if not listener then
        return 0
    end
    local distance = (tracker.root.Position - listener).Magnitude
    local scale = CombatAudioLogic.remoteFireVolume(
        distance,
        Constants.FOOTSTEP_FULL_VOLUME_STUDS,
        Constants.FOOTSTEP_MAX_STUDS
    )
    if scale < Constants.FOOTSTEP_AUDIBLE_MIN then
        return 0
    end
    return scale * Constants.FOOTSTEP_REMOTE_NEAR_CAP
end

local function unbind(model: Model)
    _trackers[model] = nil
end

local function bindReady(model: Model, isLocal: boolean)
    if _trackers[model] then
        return
    end
    if model:GetAttribute(Constants.PRACTICE_DUMMY_ATTRIBUTE) == true then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    if not root or not root:IsA("BasePart") then
        return
    end

    suppressDefaultBodySounds(root)

    _trackers[model] = {
        model = model,
        humanoid = humanoid,
        root = root,
        accum = 0,
        isLocal = isLocal,
    }

    model.Destroying:Connect(function()
        unbind(model)
    end)
end

local function bind(model: Model, isLocal: boolean)
    if _trackers[model] then
        return
    end
    if model:GetAttribute(Constants.PRACTICE_DUMMY_ATTRIBUTE) == true then
        return
    end

    task.spawn(function()
        local humanoid = model:WaitForChild("Humanoid", 5)
        local root = model:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not humanoid:IsA("Humanoid") then
            return
        end
        if not root or not root:IsA("BasePart") then
            return
        end
        if model.Parent == nil then
            return
        end
        bindReady(model, isLocal)
    end)
end

local function bindPlayer(player: Player)
    local function onCharacter(character: Model)
        bind(character, player == Players.LocalPlayer)
    end
    if player.Character then
        onCharacter(player.Character)
    end
    player.CharacterAdded:Connect(onCharacter)
end

local function watchBotFolder(folder: Instance)
    local function tryBot(inst: Instance)
        if inst:IsA("Model") and inst:GetAttribute(Constants.BOT_ATTRIBUTE) == true then
            bind(inst, false)
        end
    end
    for _, child in folder:GetChildren() do
        tryBot(child)
    end
    folder.ChildAdded:Connect(tryBot)
end

local function tick(dt: number)
    for model, tracker in _trackers do
        if model.Parent == nil then
            unbind(model)
            continue
        end
        if model:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
            tracker.accum = 0
            continue
        end
        if tracker.humanoid.Health <= 0 then
            tracker.accum = 0
            continue
        end

        local speed = horizontalSpeed(tracker.root)
        local onGround = isOnGround(tracker.humanoid)
        if not FootstepLogic.shouldAccumulate(speed, Constants.FOOTSTEP_MIN_SPEED, onGround) then
            tracker.accum = 0
            continue
        end

        tracker.accum += speed * dt
        local steps
        steps, tracker.accum =
            FootstepLogic.consumeStrides(tracker.accum, Constants.FOOTSTEP_STRIDE_STUDS)
        if steps <= 0 then
            continue
        end

        local vol = volumeForTracker(tracker)
        if vol < Constants.FOOTSTEP_AUDIBLE_MIN then
            continue
        end
        -- Cap spam if huge dt hitch: one step max per frame.
        SoundManager.playOneShot("footstep", vol)
    end
end

function FootstepController.start()
    if _started then
        return
    end
    _started = true

    for _, player in Players:GetPlayers() do
        bindPlayer(player)
    end
    Players.PlayerAdded:Connect(bindPlayer)

    local bots = Workspace:FindFirstChild("DuelBots")
    if bots then
        watchBotFolder(bots)
    end
    Workspace.ChildAdded:Connect(function(child)
        if child.Name == "DuelBots" then
            watchBotFolder(child)
        end
    end)

    _conn = RunService.Heartbeat:Connect(tick)
end

return FootstepController
