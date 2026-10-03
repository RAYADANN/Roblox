--!strict
-- Local cutscene: camera overlooks stands, new pad drops from the sky, HUD returns.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local HudGate = require(script.Parent.Parent.ui.util.HudGate)
local StandPadTierVisual = require(script.Parent.StandPadTierVisual)
local StandUnlockVisual = require(script.Parent.StandUnlockVisual)

local PadUnlockCutscene = {}

local _busy = false

local DROP_HEIGHT = 42
local DROP_SEC = 0.85
local HOLD_SEC = 0.45
local CAM_BLEND_SEC = 0.35
--- High isometric look similar to stand overview shot.
local CAM_OFFSET = Vector3.new(0, 38, 28)

local function getStandModel(padIndex: number): Model?
    local stand = StandUnlockVisual.getStand(padIndex)
    if stand and stand:IsA("Model") then
        return stand
    end
    return nil
end

local function focusPoint(stand: Model): Vector3
    local pad = stand:FindFirstChild("BoxPlace") or stand:FindFirstChild("EggPlace")
    if pad and pad:IsA("BasePart") then
        return pad.Position
    end
    return stand:GetPivot().Position
end

local function setPartsCollide(stand: Model, enabled: boolean)
    for _, d in stand:GetDescendants() do
        if d:IsA("BasePart") then
            d.CanCollide = enabled
            d.CanQuery = enabled
            d.CanTouch = enabled
        end
    end
end

local function revealVisible(stand: Model)
    for _, d in stand:GetDescendants() do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = 0
        elseif d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = 0
        end
    end
end

function PadUnlockCutscene.isBusy(): boolean
    return _busy
end

function PadUnlockCutscene.play(padIndex: number, onDone: (() -> ())?)
    local PadTierCutscene = require(script.Parent.PadTierCutscene)
    if _busy or PadTierCutscene.isBusy() then
        if onDone then
            onDone()
        end
        return
    end
    local stand = getStandModel(padIndex)
    if not stand then
        StandUnlockVisual.finishReveal(padIndex)
        if onDone then
            onDone()
        end
        return
    end

    _busy = true
    HudGate.setVisible(false)

    local cam = Workspace.CurrentCamera
    local player = Players.LocalPlayer
    local prevType = if cam then cam.CameraType else Enum.CameraType.Custom
    local prevCf = if cam then cam.CFrame else CFrame.identity
    local prevSubject = if cam then cam.CameraSubject else nil

    local restPivot = stand:GetPivot()
    local focus = focusPoint(stand)
    local startPivot = restPivot + Vector3.new(0, DROP_HEIGHT, 0)

    -- Lift while still hidden, then show and drop.
    stand:PivotTo(startPivot)
    revealVisible(stand)
    setPartsCollide(stand, false)

    if cam then
        cam.CameraType = Enum.CameraType.Scriptable
        local lookFrom = focus + CAM_OFFSET
        local targetCf = CFrame.lookAt(lookFrom, focus)
        local blend = TweenService:Create(
            cam,
            TweenInfo.new(CAM_BLEND_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = targetCf }
        )
        blend:Play()
        blend.Completed:Wait()
        if cam.Parent then
            cam.CFrame = targetCf
        end
    end

    -- Drop with Bounce-ish ease.
    local t0 = os.clock()
    local dropConn: RBXScriptConnection? = nil
    dropConn = RunService.RenderStepped:Connect(function()
        local a = math.clamp((os.clock() - t0) / DROP_SEC, 0, 1)
        -- Ease out back-ish: settle past then settle.
        local eased = 1 - (1 - a) ^ 3
        local y = DROP_HEIGHT * (1 - eased)
        stand:PivotTo(restPivot + Vector3.new(0, y, 0))
        if a >= 1 and dropConn then
            dropConn:Disconnect()
            dropConn = nil
        end
    end)

    task.wait(DROP_SEC + 0.05)
    if dropConn then
        dropConn:Disconnect()
        dropConn = nil
    end
    stand:PivotTo(restPivot)
    task.wait(HOLD_SEC)

    StandUnlockVisual.finishReveal(padIndex)
    StandPadTierVisual.reapply()

    if cam then
        local back = TweenService:Create(
            cam,
            TweenInfo.new(CAM_BLEND_SEC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = prevCf }
        )
        back:Play()
        back.Completed:Wait()
        cam.CameraType = prevType
        cam.CameraSubject = prevSubject
        if player and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                cam.CameraSubject = hum
            end
        end
    end

    HudGate.setVisible(true)
    _busy = false
    if onDone then
        onDone()
    end
end

function PadUnlockCutscene.playAsync(padIndex: number)
    task.spawn(function()
        PadUnlockCutscene.play(padIndex)
    end)
end

--- Studio/debug: U → replay pad drop cutscene (cycles Stand2..5).
function PadUnlockCutscene.bindDebugHotkey()
    local studioRun = game:GetService("RunService")
    if not studioRun:IsStudio() then
        return
    end
    local UserInputService = game:GetService("UserInputService")
    local debugPad = 2
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode ~= Enum.KeyCode.U then
            return
        end
        if _busy then
            return
        end
        local PadTierCutscene = require(script.Parent.PadTierCutscene)
        if PadTierCutscene.isBusy() then
            return
        end
        local padIndex = debugPad
        debugPad = if debugPad >= 5 then 2 else debugPad + 1
        StandUnlockVisual.setPendingPad(padIndex)
        local stand = getStandModel(padIndex)
        if stand then
            for _, d in stand:GetDescendants() do
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = 1
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d.Transparency = 1
                end
            end
        end
        PadUnlockCutscene.playAsync(padIndex)
    end)
end

return PadUnlockCutscene
