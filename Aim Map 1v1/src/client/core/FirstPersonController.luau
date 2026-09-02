--!strict
-- Lock first-person camera, hide cursor in combat.
-- FP: hide entire local world body — arms+USP live on the camera ViewModel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.shared.data.Constants)

local FirstPersonController = {}

local menuUnlock = false
local altUnlock = false
local listeners: { (free: boolean) -> () } = {}

local function applyFpMeshVisibility(character: Model)
    for _, desc in character:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.LocalTransparencyModifier = 1
        elseif desc:IsA("Decal") then
            desc.Transparency = 1
        end
    end
end

local function showLocalCharacter(character: Model)
    for _, desc in character:GetDescendants() do
        if desc:IsA("BasePart") then
            desc.LocalTransparencyModifier = 0
        elseif desc:IsA("Decal") then
            desc.Transparency = 0
        end
    end
end

local function isRagdolled(character: Model): boolean
    return character:GetAttribute(Constants.RAGDOLL_ATTRIBUTE) == true
end

local function applyAliveFirstPerson(player: Player, character: Model)
    -- Scriptable look owns the camera. Zoom 0.5 triggers Roblox FP transparency
    -- (local body + often other R15s become head-only). Keep zoom out of FP range.
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMaxZoomDistance = 32
    player.CameraMinZoomDistance = 12
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraSubject = nil
    end
    applyFpMeshVisibility(character)
end

local function applyDeathCamera(player: Player, character: Model)
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMaxZoomDistance = 16
    player.CameraMinZoomDistance = 6
    showLocalCharacter(character)
    local camera = workspace.CurrentCamera
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if camera and humanoid then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
    end
end

local function applyCursorLock()
    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function releaseCursor()
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

local function isFree(): boolean
    return menuUnlock or altUnlock
end

local function applyCursorVisual()
    if isFree() then
        releaseCursor()
    else
        applyCursorLock()
    end
end

local function setStateAndNotify(mutate: () -> ())
    local before = isFree()
    mutate()
    applyCursorVisual()
    local after = isFree()
    if after ~= before then
        for _, listener in listeners do
            listener(after)
        end
    end
end

function FirstPersonController.isCursorFree(): boolean
    return isFree()
end

function FirstPersonController.onCursorFreeChanged(listener: (free: boolean) -> ()): () -> ()
    table.insert(listeners, listener)
    listener(isFree())
    return function()
        local i = table.find(listeners, listener)
        if i then
            table.remove(listeners, i)
        end
    end
end

function FirstPersonController.setMenuCursorUnlock(enabled: boolean)
    setStateAndNotify(function()
        menuUnlock = enabled
    end)
end

function FirstPersonController.toggleAltCursor()
    setStateAndNotify(function()
        altUnlock = not altUnlock
    end)
    return altUnlock
end

function FirstPersonController.setCombatCursorLock(enabled: boolean)
    FirstPersonController.setMenuCursorUnlock(not enabled)
end

local function onCharacter(character: Model)
    local player = Players.LocalPlayer
    applyCursorVisual()
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid and humanoid:IsA("Humanoid") then
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        -- LookController owns yaw; AutoRotate would fight Scriptable FP look.
        humanoid.AutoRotate = false
    end
    if isRagdolled(character) then
        applyDeathCamera(player, character)
    else
        applyAliveFirstPerson(player, character)
    end
    character:GetAttributeChangedSignal(Constants.RAGDOLL_ATTRIBUTE):Connect(function()
        if isRagdolled(character) then
            applyDeathCamera(player, character)
        else
            applyAliveFirstPerson(player, character)
        end
    end)
    character.DescendantAdded:Connect(function(desc)
        if isRagdolled(character) then
            return
        end
        if desc:IsA("BasePart") then
            desc.LocalTransparencyModifier = 1
        elseif desc:IsA("Decal") then
            desc.Transparency = 1
        end
    end)
end

function FirstPersonController.start()
    local player = Players.LocalPlayer
    local watched: Model? = nil
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMaxZoomDistance = 32
    player.CameraMinZoomDistance = 12
    applyCursorVisual()

    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    end)

    local function watchCharacter(character: Model)
        if watched == character then
            return
        end
        watched = character
        onCharacter(character)
    end

    local function onCharacterMaybe()
        local character = player.Character
        if character then
            watchCharacter(character)
        end
    end

    onCharacterMaybe()
    player.CharacterAdded:Connect(watchCharacter)
    player:GetPropertyChangedSignal("Character"):Connect(onCharacterMaybe)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.LeftAlt then
            FirstPersonController.toggleAltCursor()
        end
    end)

    RunService.RenderStepped:Connect(function()
        applyCursorVisual()
        local character = player.Character
        if not character or isRagdolled(character) then
            return
        end
        for _, desc in character:GetDescendants() do
            if desc:IsA("BasePart") then
                desc.LocalTransparencyModifier = 1
            end
        end
    end)
end

return FirstPersonController
