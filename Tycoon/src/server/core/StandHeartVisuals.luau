--!strict
-- Heart Skin: Stand Cube + Plane → #ffaaff; enable ParticleEmitters under Stand.Part.
-- Server applies on the player plot so all clients see it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.shared.util.Logger)

local HEART_COLOR = Color3.fromRGB(255, 170, 255) -- #ffaaff
-- Cube.002 is the rim — do not recolor.
local COLOR_PARTS = { "Cube", "Plane" }
local BASE_ATTR = "HeartSkinBaseColor"

local StandHeartVisuals = {}

local function rememberBaseColor(part: BasePart)
    if part:GetAttribute(BASE_ATTR) == nil then
        part:SetAttribute(BASE_ATTR, part.Color)
    end
end

local function restoreBaseColor(part: BasePart)
    local base = part:GetAttribute(BASE_ATTR)
    if typeof(base) == "Color3" then
        part.Color = base
    end
end

local function setParticleEnabled(inst: Instance, enabled: boolean)
    if inst:IsA("ParticleEmitter") then
        inst.Enabled = enabled
    elseif
        inst:IsA("Beam")
        or inst:IsA("Trail")
        or inst:IsA("Fire")
        or inst:IsA("Smoke")
        or inst:IsA("Sparkles")
        or inst:IsA("PointLight")
        or inst:IsA("SpotLight")
        or inst:IsA("SurfaceLight")
    then
        (inst :: any).Enabled = enabled
    end
end

local function enableFxUnder(root: Instance, enabled: boolean)
    setParticleEnabled(root, enabled)
    for _, d in root:GetDescendants() do
        setParticleEnabled(d, enabled)
    end
end

function StandHeartVisuals.apply(island: Folder, owned: boolean)
    local stand = island:FindFirstChild("Stand")
    if stand == nil then
        return
    end

    for _, name in COLOR_PARTS do
        local part = stand:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            rememberBaseColor(part)
            if owned then
                part.Color = HEART_COLOR
            else
                restoreBaseColor(part)
            end
        end
    end

    -- FX root: Stand.Part (direct or nested). Enable every ParticleEmitter inside it.
    local fxRoot = stand:FindFirstChild("Part")
    if fxRoot == nil then
        fxRoot = stand:FindFirstChild("Part", true)
    end
    if fxRoot == nil then
        if owned then
            Logger.warn("StandHeartVisuals", `{island.Name}.Stand missing Part (Particle FX root)`)
        end
        return
    end

    enableFxUnder(fxRoot, owned)
end

return StandHeartVisuals
