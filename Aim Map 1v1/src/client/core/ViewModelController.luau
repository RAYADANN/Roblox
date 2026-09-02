--!strict
-- Local-only FP viewmodel: arms + USP cloned onto the camera.
-- World character still plays Idle/Shoot for replication; this is what YOU see.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local UspVisualLogic = require(ReplicatedStorage.shared.util.UspVisualLogic)
local ViewModelLogic = require(ReplicatedStorage.shared.util.ViewModelLogic)

local ViewModelController = {}

local BIND_NAME = "AimMapViewModel"
local FOLDER_NAME = "WeaponAnims"
local IDLE_FADE = 0.15
local SHOOT_FADE_IN = 0.1
local SHOOT_FADE_OUT = 0.14

local _started = false
local _model: Model? = nil
local _root: BasePart? = nil
local _idle: AnimationTrack? = nil
local _shoot: AnimationTrack? = nil
local _shootGen = 0
local _idleId: string? = nil
local _shootId: string? = nil
local _buildGen = 0
local _targetCharacter: Model? = nil
local _building = false
local _eyeHeight = Constants.FP_EYE_HEIGHT
local _localOffset = CFrame.new(
    ViewModelLogic.cameraLocalOffset(
        _eyeHeight,
        Constants.VIEWMODEL_OFFSET_RIGHT,
        Constants.VIEWMODEL_OFFSET_UP,
        Constants.VIEWMODEL_OFFSET_FORWARD
    )
)

local function registerSequence(seq: KeyframeSequence): string?
    local ok, content = pcall(function()
        return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
    end)
    if not ok or typeof(content) ~= "string" or content == "" then
        return nil
    end
    return content
end

local function ensureAnimIds()
    if _idleId and _shootId then
        return
    end
    local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 8)
    if not folder or not folder:IsA("Folder") then
        return
    end
    local idleSeq = folder:FindFirstChild("Idle")
    if not (idleSeq and idleSeq:IsA("KeyframeSequence")) then
        idleSeq = folder:FindFirstChild("AimIdle")
    end
    local shootSeq = folder:FindFirstChild("Shoot2")
    if not (shootSeq and shootSeq:IsA("KeyframeSequence")) then
        shootSeq = folder:FindFirstChild("Shoot")
    end
    if idleSeq and idleSeq:IsA("KeyframeSequence") then
        _idleId = registerSequence(idleSeq)
    end
    if shootSeq and shootSeq:IsA("KeyframeSequence") then
        _shootId = registerSequence(shootSeq)
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
        return nil
    end
    return track :: AnimationTrack
end

local function destroyViewModel()
    if _idle then
        _idle:Stop(0)
        _idle = nil
    end
    if _shoot then
        _shoot:Stop(0)
        _shoot = nil
    end
    _root = nil
    if _model then
        _model:Destroy()
        _model = nil
    end
end

local function stripClone(vm: Model)
    local remove: { Instance } = {}
    for _, desc in vm:GetDescendants() do
        local strip = desc:IsA("Script")
            or desc:IsA("LocalScript")
            or desc:IsA("Animator")
            or desc:IsA("Accessory")
            or (desc:IsA("BasePart") and ViewModelLogic.shouldStripPart(desc.Name))
        if strip then
            table.insert(remove, desc)
        end
    end
    for _, inst in remove do
        inst:Destroy()
    end

    for _, desc in vm:GetDescendants() do
        if desc:IsA("BasePart") then
            -- Only root anchored; Motor6Ds need free parts to apply Transform.
            desc.Anchored = desc.Name == "HumanoidRootPart"
            desc.CanCollide = false
            desc.CanQuery = false
            desc.CanTouch = false
            desc.Massless = true
            desc.CastShadow = false
            if ViewModelLogic.shouldHideMesh(desc.Name) then
                desc.Transparency = 1
                desc.LocalTransparencyModifier = 1
            else
                desc.LocalTransparencyModifier = 0
            end
        elseif desc:IsA("Decal") then
            desc.Transparency = 0
        end
    end
end

local function hasGun(character: Model): boolean
    for _, child in character:GetChildren() do
        if child:IsA("Model") and UspVisualLogic.isGunModelName(child.Name) then
            return true
        end
    end
    return character:FindFirstChild("USPGrip", true) ~= nil
end

--- Wait until this character is the live uniform + USP rig (post-LoadCharacter swap).
local function waitUntilReady(character: Model, gen: number): boolean
    for _ = 1, 80 do
        if gen ~= _buildGen then
            return false
        end
        local player = Players.LocalPlayer
        if player.Character ~= character or character.Parent == nil then
            return false
        end
        if character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
            return false
        end
        if
            character:GetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE) == true and hasGun(character)
        then
            return true
        end
        task.wait(0.05)
    end
    return false
end

local function cloneCharacter(character: Model): Model?
    local wasArchivable = character.Archivable
    character.Archivable = true
    local vm = character:Clone()
    character.Archivable = wasArchivable
    if not vm then
        Logger.warn("ViewModelController", "character:Clone() returned nil (Archivable?)")
        return nil
    end
    return vm
end

local function buildFromCharacter(character: Model, gen: number): boolean
    -- Wait BEFORE destroying the current viewmodel so a stale spawn cannot wipe a good one.
    if not waitUntilReady(character, gen) then
        return false
    end
    if gen ~= _buildGen or Players.LocalPlayer.Character ~= character then
        return false
    end

    local vm = cloneCharacter(character)
    if not vm then
        return false
    end
    vm.Name = "ViewModel"
    vm:SetAttribute(Constants.VIEWMODEL_ATTRIBUTE, true)
    vm:SetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE, nil)

    local worldHead = character:FindFirstChild("Head")
    local worldRoot = character:FindFirstChild("HumanoidRootPart")
    if worldHead and worldHead:IsA("BasePart") and worldRoot and worldRoot:IsA("BasePart") then
        _eyeHeight = ViewModelLogic.eyeHeight(
            worldHead.Position.Y,
            worldRoot.Position.Y,
            Constants.FP_EYE_HEIGHT
        )
    else
        _eyeHeight = Constants.FP_EYE_HEIGHT
    end
    _localOffset = CFrame.new(
        ViewModelLogic.cameraLocalOffset(
            _eyeHeight,
            Constants.VIEWMODEL_OFFSET_RIGHT,
            Constants.VIEWMODEL_OFFSET_UP,
            Constants.VIEWMODEL_OFFSET_FORWARD
        )
    )

    stripClone(vm)

    local gun = UspVisualLogic.findGunModel(vm)
    if gun then
        UspVisualLogic.assembleGunToHandle(gun)
        UspVisualLogic.prepareMuzzleParts(gun)
    end

    local humanoid = vm:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:Destroy()
    end

    local animController = Instance.new("AnimationController")
    animController.Name = "AnimationController"
    animController.Parent = vm
    local animator = Instance.new("Animator")
    animator.Parent = animController

    local root = vm:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        vm:Destroy()
        return false
    end
    vm.PrimaryPart = root

    local cam = workspace.CurrentCamera
    if not cam then
        vm:Destroy()
        return false
    end

    if gen ~= _buildGen or Players.LocalPlayer.Character ~= character then
        vm:Destroy()
        return false
    end

    ensureAnimIds()
    local idle = if _idleId then loadId(animator, _idleId, "Idle") else nil
    local shoot = if _shootId then loadId(animator, _shootId, "Shoot2") else nil
    if idle then
        idle.Looped = true
        idle.Priority = Enum.AnimationPriority.Action
        idle:Play(IDLE_FADE)
    end
    if shoot then
        shoot.Looped = false
        shoot.Priority = Enum.AnimationPriority.Action2
    end

    destroyViewModel()
    vm.Parent = workspace
    _model = vm
    _root = root
    _idle = idle
    _shoot = shoot
    _shootGen = 0

    root.CFrame = cam.CFrame * _localOffset
    return true
end

local function viewModelLive(): boolean
    local model = _model
    local root = _root
    return model ~= nil and model.Parent ~= nil and root ~= nil
end

local function characterReady(character: Model): boolean
    if character.Parent == nil then
        return false
    end
    if character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
        return false
    end
    if character:GetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE) ~= true then
        return false
    end
    return hasGun(character)
end

local function scheduleBuild(character: Model)
    _targetCharacter = character
    _buildGen += 1
    local gen = _buildGen
    _building = true
    task.spawn(function()
        buildFromCharacter(character, gen)
        if gen == _buildGen then
            _building = false
        end
    end)
end

local function cancelBuildsAndDestroy()
    _buildGen += 1
    _building = false
    destroyViewModel()
end

local function ensureViewModel()
    local character = Players.LocalPlayer.Character
    if not character or not characterReady(character) then
        return
    end
    if viewModelLive() or _building then
        return
    end
    scheduleBuild(character)
end

local function update()
    local root = _root
    local model = _model
    local cam = workspace.CurrentCamera
    if not root or not model or not cam then
        return
    end
    if model.Parent ~= workspace then
        model.Parent = workspace
    end
    root.CFrame = cam.CFrame * _localOffset
end

function ViewModelController.playShoot()
    local shoot = _shoot
    if not shoot then
        return
    end
    _shootGen += 1
    local gen = _shootGen
    shoot:Play(SHOOT_FADE_IN, 1, 1)
    local length = shoot.Length
    if length <= SHOOT_FADE_OUT + 0.02 then
        return
    end
    task.delay(length - SHOOT_FADE_OUT, function()
        if _shootGen ~= gen then
            return
        end
        if shoot.IsPlaying then
            shoot:Stop(SHOOT_FADE_OUT)
        end
    end)
end

function ViewModelController.getModel(): Model?
    return _model
end

function ViewModelController.start()
    if _started then
        return
    end
    _started = true

    task.spawn(ensureAnimIds)

    local player = Players.LocalPlayer
    local watched: Model? = nil

    local function watchCharacter(character: Model)
        if watched == character then
            return
        end
        watched = character
        scheduleBuild(character)

        local ragdollConn = character
            :GetAttributeChangedSignal(Constants.RAGDOLL_ATTRIBUTE)
            :Connect(function()
                if character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
                    cancelBuildsAndDestroy()
                elseif player.Character == character then
                    scheduleBuild(character)
                end
            end)
        local uniformConn = character
            :GetAttributeChangedSignal(Constants.UNIFORM_RIG_ATTRIBUTE)
            :Connect(function()
                if
                    player.Character == character
                    and character:GetAttribute(Constants.UNIFORM_RIG_ATTRIBUTE) == true
                    and character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) ~= true
                then
                    scheduleBuild(character)
                end
            end)
        character.Destroying:Connect(function()
            ragdollConn:Disconnect()
            uniformConn:Disconnect()
            if watched == character then
                watched = nil
            end
        end)
    end

    local function onCharacterMaybe()
        local character = player.Character
        if character then
            watchCharacter(character)
        end
    end

    onCharacterMaybe()
    player.CharacterAdded:Connect(watchCharacter)
    -- UniformCharacter assigns player.Character = rig; PropertyChanged covers missed CharacterAdded.
    player:GetPropertyChangedSignal("Character"):Connect(onCharacterMaybe)
    -- Only cancel the build for the character that is leaving. CharacterRemoving
    -- of the *old* avatar often fires after CharacterAdded of the dummy and used
    -- to kill the new viewmodel with no retry.
    player.CharacterRemoving:Connect(function(removing)
        if removing == _targetCharacter then
            cancelBuildsAndDestroy()
        end
        if watched == removing then
            watched = nil
        end
    end)

    -- Catch missed CharacterAdded / timed-out waits (LoadCharacter + uniform swap).
    task.spawn(function()
        while _started do
            task.wait(0.4)
            ensureViewModel()
        end
    end)

    RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 2, update)
end

return ViewModelController
