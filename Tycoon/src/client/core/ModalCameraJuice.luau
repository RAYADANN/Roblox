--!strict
-- Modal open/close camera juice: FOV zoom + slight Humanoid.CameraOffset.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SettingsManager = require(script.Parent.SettingsManager)

local FOV_ZOOM = 7
local OFFSET_OPEN = Vector3.new(0, 0.4, 0)
local OPEN_INFO = TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local ModalCameraJuice = {}

local _open = false
local _baseFov: number? = nil
local _active: { Tween } = {}

local function cancelActive()
    for _, tween in _active do
        tween:Cancel()
    end
    table.clear(_active)
end

local function play(tween: Tween)
    table.insert(_active, tween)
    tween:Play()
end

local function getCamera(): Camera?
    return Workspace.CurrentCamera
end

local function getHumanoid(): Humanoid?
    local player = Players.LocalPlayer
    local character = player and player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function snapRestore()
    cancelActive()
    local cam = getCamera()
    local base = _baseFov
    if cam and base ~= nil then
        cam.FieldOfView = base
    end
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.CameraOffset = Vector3.zero
    end
    _baseFov = nil
    _open = false
end

function ModalCameraJuice.setOpen(open: boolean)
    if SettingsManager.isReduceMotion() then
        if _open and not open then
            snapRestore()
        end
        return
    end

    if open == _open then
        return
    end

    cancelActive()
    local cam = getCamera()
    if cam == nil then
        _open = open
        return
    end

    if open then
        if _baseFov == nil then
            _baseFov = cam.FieldOfView
        end
        local base = _baseFov :: number
        local targetFov = math.clamp(base - FOV_ZOOM, 50, 120)
        play(TweenService:Create(cam, OPEN_INFO, { FieldOfView = targetFov }))
        local humanoid = getHumanoid()
        if humanoid then
            play(TweenService:Create(humanoid, OPEN_INFO, { CameraOffset = OFFSET_OPEN }))
        end
        _open = true
    else
        local base = _baseFov or cam.FieldOfView
        play(TweenService:Create(cam, CLOSE_INFO, { FieldOfView = base }))
        local humanoid = getHumanoid()
        if humanoid then
            play(TweenService:Create(humanoid, CLOSE_INFO, { CameraOffset = Vector3.zero }))
        end
        _baseFov = nil
        _open = false
    end
end

return ModalCameraJuice
