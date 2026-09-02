--!strict
-- Custom first-person look. Scriptable camera; body yaw follows look yaw.
-- Arms+USP are a separate ViewModel on the camera (see ViewModelController).
-- Recoil/camera punch is applied here (Humanoid.CameraOffset does not affect Scriptable).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.shared.data.Constants)
local FirstPersonController = require(script.Parent.FirstPersonController)
local RecoilLogic = require(ReplicatedStorage.shared.util.RecoilLogic)
local SensitivityLogic = require(ReplicatedStorage.shared.util.SensitivityLogic)
local SettingsManager = require(script.Parent.SettingsManager)
local ViewModelLogic = require(ReplicatedStorage.shared.util.ViewModelLogic)

local LookController = {}

local BIND_NAME = "AimMapLook"
local sensitivity = Constants.LOOK_SENSITIVITY_DEFAULT
local yaw = 0
local pitch = 0
local recoilPitch = 0
local recoilYaw = 0
local lastClock = os.clock()
local started = false

-- Match classic PlayerModule mouse scale at sens = 1.
local ROT_X = math.rad(0.5)
local ROT_Y = math.rad(0.5) * 0.77
local PITCH_MIN = math.rad(-80)
local PITCH_MAX = math.rad(80)

local function characterRoot(character: Model): BasePart?
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function eyeOrigin(character: Model, root: BasePart): Vector3
    local head = character:FindFirstChild("Head")
    local eyeH = Constants.FP_EYE_HEIGHT
    if head and head:IsA("BasePart") then
        eyeH = ViewModelLogic.eyeHeight(head.Position.Y, root.Position.Y, Constants.FP_EYE_HEIGHT)
    end
    local pos = root.Position
    return Vector3.new(pos.X, pos.Y + eyeH, pos.Z)
end

-- Yaw from the capsule, pitch 0. Default CameraModule often looks down at spawn.
local function syncAnglesFromCharacter(character: Model)
    local root = characterRoot(character)
    if not root then
        return
    end
    local look = root.CFrame.LookVector
    yaw = math.atan2(-look.X, -look.Z)
    pitch = 0
    recoilPitch = 0
    recoilYaw = 0
end

function LookController.setSensitivity(value: number)
    sensitivity = SensitivityLogic.clamp(value)
    -- Keep default module from also scaling if it briefly runs.
    UserInputService.MouseDeltaSensitivity = 1
    local player = Players.LocalPlayer
    if player then
        player:SetAttribute("AimLookSens", sensitivity)
    end
end

function LookController.getSensitivity(): number
    return sensitivity
end

function LookController.resetFromCamera()
    local character = Players.LocalPlayer.Character
    if character then
        syncAnglesFromCharacter(character)
    end
end

--- Local fire camera punch (call on shot intent — don't wait for server).
function LookController.punchFire()
    local dp, dy, keep = RecoilLogic.kick(math.random(), SettingsManager.isReduceMotion())
    recoilPitch, recoilYaw = RecoilLogic.clampStack(recoilPitch + dp, recoilYaw + dy)
    pitch = math.clamp(pitch + keep, PITCH_MIN, PITCH_MAX)
end

local function update()
    local now = os.clock()
    local dt = math.clamp(now - lastClock, 0, 0.05)
    lastClock = now

    local player = Players.LocalPlayer
    local character = player.Character
    local cam = workspace.CurrentCamera
    if not character or not cam then
        return
    end

    -- Death cam: do not drive Scriptable FP / root CFrame (would fight ragdoll).
    if character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true then
        cam.CameraType = Enum.CameraType.Custom
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            cam.CameraSubject = humanoid
        end
        recoilPitch = 0
        recoilYaw = 0
        return
    end

    local root = characterRoot(character)
    if not root then
        return
    end

    cam.CameraType = Enum.CameraType.Scriptable
    -- Humanoid subject + first-person zoom makes PlayerModule hide R15 bodies (head-only).
    cam.CameraSubject = nil

    if not FirstPersonController.isCursorFree() then
        local delta = UserInputService:GetMouseDelta()
        local sens = sensitivity
        yaw -= delta.X * ROT_X * sens
        pitch = math.clamp(pitch - delta.Y * ROT_Y * sens, PITCH_MIN, PITCH_MAX)
    end

    recoilPitch, recoilYaw =
        RecoilLogic.decay(recoilPitch, recoilYaw, dt, Constants.USP_RECOIL_RECOVER_RATE)

    local origin = eyeOrigin(character, root)
    cam.CFrame = CFrame.new(origin)
        * CFrame.Angles(0, yaw + recoilYaw, 0)
        * CFrame.Angles(pitch + recoilPitch, 0, 0)

    -- Keep walk direction aligned with look yaw (true aim, not punch wobble).
    local pos = root.Position
    root.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

function LookController.start()
    if started then
        return
    end
    started = true
    LookController.setSensitivity(sensitivity)
    lastClock = os.clock()

    local player = Players.LocalPlayer
    local function resetLook(character: Model)
        task.defer(function()
            if player.Character == character then
                syncAnglesFromCharacter(character)
            end
        end)
    end
    local function onCharacterMaybe()
        local character = player.Character
        if character then
            resetLook(character)
        end
    end
    onCharacterMaybe()
    player.CharacterAdded:Connect(resetLook)
    player:GetPropertyChangedSignal("Character"):Connect(onCharacterMaybe)

    RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, update)
end

return LookController
