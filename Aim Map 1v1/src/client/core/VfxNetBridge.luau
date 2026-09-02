--!strict
-- Client: Zap PlayVfx → VfxController.play (all clients render).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatAudioLogic = require(ReplicatedStorage.shared.util.CombatAudioLogic)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local Logger = require(ReplicatedStorage.shared.util.Logger)
local SkinDatabase = require(ReplicatedStorage.shared.data.SkinDatabase)
local SoundManager = require(script.Parent.SoundManager)
local VfxController = require(script.Parent.VfxController)
local WeaponAnimController = require(script.Parent.WeaponAnimController)
local Zap = require(script.Parent.Parent.net.NetClient)

local VfxNetBridge = {}

local _started = false

local function listenerPosition(): Vector3?
    local camera = workspace.CurrentCamera
    if camera then
        return camera.CFrame.Position
    end
    local character = Players.LocalPlayer.Character
    if not character then
        return nil
    end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head.Position
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root.Position
    end
    return nil
end

local function playRemoteUspFire(origin: Vector3)
    local listener = listenerPosition()
    if not listener then
        return
    end
    local distance = (origin - listener).Magnitude
    local scale = CombatAudioLogic.remoteFireVolume(
        distance,
        Constants.REMOTE_FIRE_FULL_VOLUME_STUDS,
        Constants.REMOTE_FIRE_MAX_STUDS
    )
    if scale < Constants.REMOTE_FIRE_AUDIBLE_MIN then
        return
    end
    SoundManager.playOneShot("usp_fire", scale * Constants.REMOTE_FIRE_NEAR_CAP)
end

local function colorFromSkinId(skinId: string?): Color3
    local id = if skinId and skinId ~= "" then skinId else Constants.DEFAULT_SKIN_ID
    local rgb = SkinDatabase.tracerRgb(id)
    return Color3.fromRGB(rgb.r, rgb.g, rgb.b)
end

function VfxNetBridge.start()
    if _started then
        return
    end
    _started = true

    Zap.PlayVfx.On(function(value)
        local ok, err = pcall(function()
            -- Enemy/bot gunfire: distance-attenuated one-shot (not full 2D mix).
            if value.effectId == "UspFire" then
                if value.pos then
                    playRemoteUspFire(value.pos)
                    WeaponAnimController.playShootNear(value.pos)
                end
                return
            end

            VfxController.start()
            local intensity = if value.intensity > 0 then value.intensity else 1
            local color = if value.effectId == "HitBody"
                    or value.effectId == "HitHead"
                    or value.effectId == "HitSurface"
                then Color3.fromRGB(115, 199, 255)
                else colorFromSkinId(value.skinId)
            VfxController.play(value.effectId, {
                cframe = if value.pos then CFrame.new(value.pos) else nil,
                from = if value.from then CFrame.new(value.from) else nil,
                to = if value.to then CFrame.new(value.to) else nil,
                intensity = intensity,
                color = color,
            })
        end)
        if not ok then
            Logger.warn("VfxNetBridge", `PlayVfx failed: {err}`)
        end
    end)

    Logger.info("VfxNetBridge", "listening for PlayVfx")
end

return VfxNetBridge
