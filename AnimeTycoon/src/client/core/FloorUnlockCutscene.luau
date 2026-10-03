--!strict
-- Local cutscene: newly unlocked floor drops from the sky onto pillars.
-- Camera: high front-facing angle overlooking the plot (see studio reference).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FloorUnlockVisual = require(script.Parent.FloorUnlockVisual)
local HudGate = require(script.Parent.Parent.ui.util.HudGate)

local FloorUnlockCutscene = {}

local _busy = false

local DROP_HEIGHT = 48
local DROP_SEC = 1.0
local HOLD_SEC = 0.4
local CAM_BLEND_SEC = 0.4
--- High front shot looking into the plot along the conveyor.
--- SecondFloor Look=+X / Right=+Z; entrance & stands are on -Right (−Z).
local CAM_DIST = 60
local CAM_HEIGHT = 40

local function setPartsCollide(model: Model, enabled: boolean)
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            d.CanCollide = enabled
            d.CanQuery = enabled
            d.CanTouch = enabled
        end
    end
end

function FloorUnlockCutscene.isBusy(): boolean
    return _busy
end

function FloorUnlockCutscene.play(floorIndex: number, onDone: (() -> ())?)
    if _busy then
        if onDone then
            onDone()
        end
        return
    end

    local floorModel = FloorUnlockVisual.getFloorModel(floorIndex)
    if not floorModel then
        FloorUnlockVisual.finishReveal(floorIndex)
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

    local restPivot = floorModel:GetPivot()
    local focus = restPivot.Position
    local startPivot = restPivot + Vector3.new(0, DROP_HEIGHT, 0)

    floorModel:PivotTo(startPivot)
    FloorUnlockVisual.revealVisible(floorModel)
    setPartsCollide(floorModel, false)

    if cam then
        cam.CameraType = Enum.CameraType.Scriptable
        -- Stand outside the entrance (−Right), look down the conveyor into the base.
        local frontDir = -restPivot.RightVector
        local lookFrom = focus + frontDir * CAM_DIST + Vector3.new(0, CAM_HEIGHT, 0)
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

    local t0 = os.clock()
    local dropConn: RBXScriptConnection? = nil
    dropConn = RunService.RenderStepped:Connect(function()
        local a = math.clamp((os.clock() - t0) / DROP_SEC, 0, 1)
        local eased = 1 - (1 - a) ^ 3
        local y = DROP_HEIGHT * (1 - eased)
        floorModel:PivotTo(restPivot + Vector3.new(0, y, 0))
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
    floorModel:PivotTo(restPivot)
    task.wait(HOLD_SEC)

    FloorUnlockVisual.finishReveal(floorIndex)

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

function FloorUnlockCutscene.playAsync(floorIndex: number)
    task.spawn(function()
        FloorUnlockCutscene.play(floorIndex)
    end)
end

--- Studio/debug: O → drop SecondFloor / ThirdFloor cutscene (cycles).
function FloorUnlockCutscene.bindDebugHotkey()
    if not RunService:IsStudio() then
        return
    end
    local UserInputService = game:GetService("UserInputService")
    local debugFloor = 2
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode ~= Enum.KeyCode.O then
            return
        end
        if _busy then
            return
        end
        local floorIndex = debugFloor
        debugFloor = if debugFloor >= 3 then 2 else 3
        FloorUnlockVisual.setPendingFloor(floorIndex)
        -- Fake unlocks so apply keeps floor pending-hidden until drop.
        local upgrades = FloorUnlockVisual.getLastUpgrades() or {}
        local u = table.clone(upgrades)
        -- base level 1 → floor 2; base 11 → floor 3
        u.base = if floorIndex >= 3 then 11 else 1
        FloorUnlockVisual.apply(u)
        local model = FloorUnlockVisual.getFloorModel(floorIndex)
        if model then
            for _, d in model:GetDescendants() do
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = 1
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d.Transparency = 1
                end
            end
        end
        FloorUnlockCutscene.playAsync(floorIndex)
    end)
end

return FloorUnlockCutscene
