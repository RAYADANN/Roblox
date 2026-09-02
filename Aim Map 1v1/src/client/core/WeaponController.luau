--!strict
-- Client fire intent: click / touch → Zap FireWeapon (server validates).
-- Hitscan origin is viewmodel Part "Shoot"; direction is Shoot → camera aim point.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.shared.data.Constants)
local DamageNumber = require(script.Parent.Parent.ui.fx.DamageNumber)
local FireCooldownState = require(script.Parent.FireCooldownState)
local FirstPersonController = require(script.Parent.FirstPersonController)
local HitMarkerState = require(script.Parent.HitMarkerState)
local KillBannerState = require(script.Parent.KillBannerState)
local LookController = require(script.Parent.LookController)
local SkinDatabase = require(ReplicatedStorage.shared.data.SkinDatabase)
local SoundManager = require(script.Parent.SoundManager)
local TracerLogic = require(ReplicatedStorage.shared.util.TracerLogic)
local UspVisualLogic = require(ReplicatedStorage.shared.util.UspVisualLogic)
local VfxController = require(script.Parent.VfxController)
local ViewModelController = require(script.Parent.ViewModelController)
local WeaponAnimController = require(script.Parent.WeaponAnimController)
local WeaponLogic = require(ReplicatedStorage.shared.util.WeaponLogic)
local Zap = require(script.Parent.Parent.net.NetClient)

local WeaponController = {}

local lastLocalShot = 0

local function cameraAimRay(): (Vector3?, Vector3?)
    local camera = workspace.CurrentCamera
    if not camera then
        return nil, nil
    end
    local viewport = camera.ViewportSize
    local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
    return ray.Origin, ray.Direction
end

local function visibleSkinId(): string
    local player = Players.LocalPlayer
    local flex = player:GetAttribute(Constants.FLEX_SKIN_ATTRIBUTE)
    if typeof(flex) == "string" and flex ~= "" then
        return flex
    end
    local equipped = player:GetAttribute(Constants.EQUIPPED_SKIN_ATTRIBUTE)
    if typeof(equipped) == "string" and equipped ~= "" then
        return equipped
    end
    return Constants.DEFAULT_SKIN_ID
end

local function fpMuzzleWorld(): Vector3?
    local viewModel = ViewModelController.getModel()
    if viewModel then
        local fromGun = UspVisualLogic.muzzleWorldPosition(viewModel)
        if fromGun then
            return fromGun
        end
    end

    -- Fallback when Shoot / USP is not on the viewmodel yet.
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end
    local cf = camera.CFrame
    local x, y, z = TracerLogic.fpMuzzleWorld(
        cf.Position.X,
        cf.Position.Y,
        cf.Position.Z,
        cf.RightVector.X,
        cf.RightVector.Y,
        cf.RightVector.Z,
        cf.UpVector.X,
        cf.UpVector.Y,
        cf.UpVector.Z,
        cf.LookVector.X,
        cf.LookVector.Y,
        cf.LookVector.Z,
        Constants.FP_TRACER_MUZZLE_RIGHT,
        Constants.FP_TRACER_MUZZLE_UP,
        Constants.FP_TRACER_MUZZLE_FORWARD
    )
    return Vector3.new(x, y, z)
end

local function cameraAimPoint(camOrigin: Vector3, camDir: Vector3): Vector3
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude: { Instance } = {}
    local character = Players.LocalPlayer.Character
    if character then
        table.insert(exclude, character)
    end
    local viewModel = ViewModelController.getModel()
    if viewModel then
        table.insert(exclude, viewModel)
    end
    params.FilterDescendantsInstances = exclude
    local hit = workspace:Raycast(camOrigin, camDir.Unit * Constants.USP_MAX_RANGE_STUDS, params)
    if hit then
        return hit.Position
    end
    return camOrigin + camDir.Unit * Constants.USP_MAX_RANGE_STUDS
end

local function playLocalTracer(traceEnd: Vector3)
    local from = fpMuzzleWorld()
    if not from then
        return
    end
    local ex, ey, ez =
        TracerLogic.fpTraceEnd(from.X, from.Y, from.Z, traceEnd.X, traceEnd.Y, traceEnd.Z)
    local rgb = SkinDatabase.tracerRgb(visibleSkinId())
    VfxController.start()
    VfxController.play("BulletTracer", {
        from = CFrame.new(from),
        to = CFrame.new(ex, ey, ez),
        color = Color3.fromRGB(rgb.r, rgb.g, rgb.b),
        intensity = 1,
    })
end

local function tryFire()
    -- Don't shoot UI while cursor is free (Alt / menus).
    if FirstPersonController.isCursorFree() then
        return
    end

    local now = os.clock()
    if now - lastLocalShot < Constants.USP_FIRE_COOLDOWN_SEC * 0.85 then
        return
    end
    local camOrigin, camDir = cameraAimRay()
    if camOrigin == nil or camDir == nil then
        return
    end

    local aimPoint = cameraAimPoint(camOrigin, camDir)
    local muzzle = fpMuzzleWorld()
    local origin = muzzle or camOrigin
    local dx, dy, dz =
        TracerLogic.muzzleAimDelta(origin.X, origin.Y, origin.Z, aimPoint.X, aimPoint.Y, aimPoint.Z)
    local direction = Vector3.new(dx, dy, dz)
    if not WeaponLogic.directionMagnitudeOk(direction.Magnitude) then
        return
    end

    lastLocalShot = now
    FireCooldownState.markShot()
    -- Punch after aim sample so this shot stays where the crosshair was.
    LookController.punchFire()
    WeaponAnimController.playShoot()
    ViewModelController.playShoot()
    SoundManager.playOneShot("usp_fire", 1)
    task.spawn(function()
        local result = Zap.FireWeapon.Call(origin, direction)
        if not result.success then
            return
        end
        if result.traceEnd then
            playLocalTracer(result.traceEnd)
        end
        if result.hitPos then
            VfxController.start()
            local dealtDamage = result.hit == true and result.damage ~= nil
            local effectId = if dealtDamage and result.headshot == true
                then "HitHead"
                elseif dealtDamage then "HitBody"
                else "HitSurface"
            VfxController.play(effectId, {
                cframe = CFrame.new(result.hitPos),
                intensity = if effectId == "HitHead"
                    then 1.2
                    elseif effectId == "HitBody" then 0.8
                    else 0.75,
                color = Color3.fromRGB(115, 199, 255),
            })
        end
        if result.hit and result.damage then
            if result.headshot then
                HitMarkerState.pulse(true, false)
            elseif not result.killed then
                HitMarkerState.pulse(false, false)
            end
            if result.killed then
                KillBannerState.pulse()
                SoundManager.playOneShot("kill", 1)
            end
            if result.hitPos then
                DamageNumber.play({
                    position = result.hitPos,
                    damage = result.damage,
                    headshot = result.headshot,
                })
            end
        end
    end)
end

function WeaponController.start()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        local fireInput = input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
            or input.KeyCode == Enum.KeyCode.ButtonR2
        if fireInput then
            tryFire()
        end
    end)

    local player = Players.LocalPlayer
    player.CameraMode = Enum.CameraMode.Classic
end

return WeaponController
