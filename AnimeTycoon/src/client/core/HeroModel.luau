--!strict
-- Clone Workspace.Secret. On HeroPlace: +90° Y (face ramp), then PlaceAlign.

local Workspace = game:GetService("Workspace")

local PlaceAlign = require(script.Parent.PlaceAlign)

local HERO_TEMPLATE_NAME = "Secret"

local HeroModel = {}

local function getTemplate(): Model?
    local secret = Workspace:FindFirstChild(HERO_TEMPLATE_NAME)
    if secret and secret:IsA("Model") then
        return secret
    end
    return nil
end

function HeroModel.clone(_heroId: string?, scale: number?): Model?
    local template = getTemplate()
    if not template then
        warn("[HeroModel] Workspace.Secret missing")
        return nil
    end
    local clone = template:Clone()
    clone.Name = "HeroVisual"
    for _, d in clone:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.Massless = true
        elseif d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy()
        end
    end
    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    -- Keep template PrimaryPart (HRP); do not reassign to a random mesh.
    local s = scale or 1
    if s ~= 1 then
        pcall(function()
            clone:ScaleTo(s)
        end)
    end
    return clone
end

function HeroModel.placeOn(model: Model, target: BasePart)
    if model.Parent == nil then
        model.Parent = Workspace
    end
    -- +90° Y toward ramp; right side needs +180 more (otherwise faces away).
    local yaw = math.rad(90)
    if target.Position.X >= 64 then
        yaw += math.rad(180)
    end
    local pivot = model:GetPivot()
    model:PivotTo(CFrame.new(pivot.Position) * pivot.Rotation * CFrame.Angles(0, yaw, 0))
    PlaceAlign.onPad(model, target, nil)
    model.Parent = target
end

return HeroModel
