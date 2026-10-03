--!strict
-- Local cutscene: old pad visuals rise, swap to Pad Upgrade tier, new visuals drop.
-- Camera matches PadUnlockCutscene (same offset / height).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.shared.data.Constants)
local HudGate = require(script.Parent.Parent.ui.util.HudGate)
local PadUnlockCutscene = require(script.Parent.PadUnlockCutscene)
local StandPadTierVisual = require(script.Parent.StandPadTierVisual)
local StandUnlockVisual = require(script.Parent.StandUnlockVisual)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)

local PadTierCutscene = {}

local _busy = false

local DROP_HEIGHT = 42
local RISE_SEC = 0.7
local DROP_SEC = 0.85
local HOLD_SEC = 0.35
local CAM_BLEND_SEC = 0.35
local CAM_OFFSET = Vector3.new(0, 38, 28)

local function getUnlockedStands(upgrades: { [string]: number }?): { Model }
    local out: { Model } = {}
    for i = 1, Constants.OFFER_COUNT do
        if UpgradeLogic.isPadUnlocked(upgrades, i) then
            local stand = StandUnlockVisual.getStand(i)
            if stand and stand:IsA("Model") then
                table.insert(out, stand)
            end
        end
    end
    return out
end

local function focusOfStands(stands: { Model }): Vector3
    if #stands == 0 then
        return Vector3.zero
    end
    local sum = Vector3.zero
    for _, stand in stands do
        local pad = stand:FindFirstChild("BoxPlace") or stand:FindFirstChild("EggPlace")
        if pad and pad:IsA("BasePart") then
            sum += pad.Position
        else
            sum += stand:GetPivot().Position
        end
    end
    return sum / #stands
end

local function setPartsCollide(stand: Model, enabled: boolean)
    for _, d in stand:GetDescendants() do
        if d:IsA("BasePart") and d.Name ~= "BoxPlace" and d.Name ~= "EggPlace" then
            d.CanCollide = enabled
            d.CanQuery = enabled
            d.CanTouch = enabled
        end
    end
end

local function animatePivots(
    stands: { Model },
    rests: { CFrame },
    fromY: number,
    toY: number,
    duration: number
)
    local t0 = os.clock()
    local conn: RBXScriptConnection? = nil
    local done = false
    conn = RunService.RenderStepped:Connect(function()
        local a = math.clamp((os.clock() - t0) / duration, 0, 1)
        local eased = 1 - (1 - a) ^ 3
        local y = fromY + (toY - fromY) * eased
        for i, stand in stands do
            stand:PivotTo(rests[i] + Vector3.new(0, y, 0))
        end
        if a >= 1 then
            done = true
            if conn then
                conn:Disconnect()
                conn = nil
            end
        end
    end)
    task.wait(duration + 0.05)
    if conn then
        conn:Disconnect()
    end
    if not done then
        for i, stand in stands do
            stand:PivotTo(rests[i] + Vector3.new(0, toY, 0))
        end
    end
end

function PadTierCutscene.isBusy(): boolean
    return _busy
end

function PadTierCutscene.play(onDone: (() -> ())?)
    if _busy or PadUnlockCutscene.isBusy() then
        if onDone then
            onDone()
        end
        return
    end

    local upgrades = StandPadTierVisual.getLastUpgrades()
    local stands = getUnlockedStands(upgrades)
    if #stands == 0 then
        StandPadTierVisual.clearHold()
        StandPadTierVisual.reapply()
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

    local rests: { CFrame } = {}
    for i, stand in stands do
        rests[i] = stand:GetPivot()
        setPartsCollide(stand, false)
    end

    local focus = focusOfStands(stands)
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

    -- Old pads rise.
    animatePivots(stands, rests, 0, DROP_HEIGHT, RISE_SEC)
    task.wait(0.12)

    -- Swap to new tier while in the sky.
    StandPadTierVisual.clearHold()
    StandPadTierVisual.reapply()
    for i, stand in stands do
        stand:PivotTo(rests[i] + Vector3.new(0, DROP_HEIGHT, 0))
        setPartsCollide(stand, false)
    end

    -- New pads fall.
    animatePivots(stands, rests, DROP_HEIGHT, 0, DROP_SEC)
    for i, stand in stands do
        stand:PivotTo(rests[i])
    end
    task.wait(HOLD_SEC)

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

function PadTierCutscene.playAsync()
    task.spawn(function()
        PadTierCutscene.play()
    end)
end

--- Studio/debug: I → cycle Pad Upgrade tier cutscene (0→1→2→3→0).
function PadTierCutscene.bindDebugHotkey()
    if not RunService:IsStudio() then
        return
    end
    local UserInputService = game:GetService("UserInputService")
    local debugTo = 1
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode ~= Enum.KeyCode.I then
            return
        end
        if _busy or PadUnlockCutscene.isBusy() then
            return
        end
        local toTier = debugTo
        local fromTier = if toTier == 0 then 3 else toTier - 1
        debugTo = if debugTo >= 3 then 0 else debugTo + 1
        StandPadTierVisual.prepareDebugCutscene(fromTier, toTier)
        PadTierCutscene.playAsync()
    end)
end

return PadTierCutscene
