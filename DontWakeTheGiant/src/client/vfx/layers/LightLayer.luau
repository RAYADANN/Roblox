--!strict
-- Короткий PointLight kick. Пул якорей.

local TweenService = game:GetService("TweenService")
local InstancePool = require(script.Parent.Parent.InstancePool)
local QualityLogic = require(game:GetService("ReplicatedStorage").shared.vfx.QualityLogic)

export type QualityBudget = QualityLogic.QualityBudget

export type LightConfig = {
    range: number?,
    brightness: number?,
    duration: number?,
}

local LightLayer = {}

local _pool: InstancePool.InstancePool? = nil

local function ensurePool(parent: Instance): InstancePool.InstancePool
    if _pool then
        return _pool
    end
    _pool = InstancePool.new({
        name = "VfxLightAnchor",
        maxSize = 32,
        parent = parent,
        factory = function()
            local anchor = Instance.new("Part")
            anchor.Name = "VfxLightAnchor"
            anchor.Anchored = true
            anchor.CanCollide = false
            anchor.CanQuery = false
            anchor.CanTouch = false
            anchor.Transparency = 1
            anchor.Size = Vector3.new(0.2, 0.2, 0.2)
            local light = Instance.new("PointLight")
            light.Name = "Pulse"
            light.Parent = anchor
            return anchor
        end,
        reset = function(inst)
            if inst:IsA("BasePart") then
                local light = inst:FindFirstChild("Pulse")
                if light and light:IsA("PointLight") then
                    light.Brightness = 0
                    light.Range = 0
                end
            end
        end,
    })
    _pool:prewarm(4)
    return _pool
end

function LightLayer.pulse(
    parent: Instance,
    cframe: CFrame,
    color: Color3,
    config: LightConfig,
    budget: QualityBudget
): Instance?
    if not budget.enableLights then
        return nil
    end

    local pool = ensurePool(parent)
    local anchor = pool:take() :: BasePart
    anchor.Parent = parent
    anchor.CFrame = cframe

    local light = anchor:FindFirstChild("Pulse") :: PointLight
    if not light then
        light = Instance.new("PointLight")
        light.Name = "Pulse"
        light.Parent = anchor
    end
    light.Color = color
    light.Range = config.range or 14
    light.Brightness = (config.brightness or 2.5) * budget.lightBrightnessScale

    local duration = config.duration or 0.28
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(light, info, { Brightness = 0 }):Play()
    task.delay(duration + 0.05, function()
        if anchor.Parent then
            pool:give(anchor)
        end
    end)
    return anchor
end

return LightLayer
