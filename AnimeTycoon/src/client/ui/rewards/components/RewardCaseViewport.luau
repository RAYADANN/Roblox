--!strict
-- 3D case preview inside a Rewards card.
-- Hoarcekat: UI lives under ReplicatedStorage.UI (no sibling core) — resolve BoxModel from StarterPlayerScripts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type Props = {
    boxModelName: string,
    mutation: string?,
    size: UDim2,
    position: UDim2,
    anchorPoint: Vector2,
    zIndex: number?,
    dimmed: boolean?,
}

local TARGET_HEIGHT = 5.0

local function resolveBoxModel(): any?
    local underClient = script.Parent.Parent.Parent.Parent
    if underClient then
        local core = underClient:FindFirstChild("core")
        local mod = core and core:FindFirstChild("BoxModel")
        if mod and mod:IsA("ModuleScript") then
            local ok, boxModel = pcall(require, mod)
            if ok then
                return boxModel
            end
        end
    end
    local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    local client = sps and sps:FindFirstChild("client")
    local core = client and client:FindFirstChild("core")
    local mod = core and core:FindFirstChild("BoxModel")
    if mod and mod:IsA("ModuleScript") then
        local ok, boxModel = pcall(require, mod)
        if ok then
            return boxModel
        end
    end
    return nil
end

local function isHelperPart(part: BasePart): boolean
    local n = string.lower(part.Name)
    if part.Transparency >= 0.99 then
        return true
    end
    if string.find(n, "mutation", 1, true) or string.find(n, "root", 1, true) then
        return true
    end
    if n == "vfxinstance" or string.find(n, "fx", 1, true) == 1 then
        return true
    end
    return false
end

--- Visible mesh bounds only (mutation FX / helpers blow up GetBoundingBox).
local function getVisibleBounds(model: Model): (Vector3, Vector3)
    local minV: Vector3? = nil
    local maxV: Vector3? = nil
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") and not isHelperPart(d) then
            local cf = d.CFrame
            local half = d.Size * 0.5
            for _, sx in { -1, 1 } do
                for _, sy in { -1, 1 } do
                    for _, sz in { -1, 1 } do
                        local corner = cf * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
                        if not minV or not maxV then
                            minV = corner
                            maxV = corner
                        else
                            minV = Vector3.new(
                                math.min(minV.X, corner.X),
                                math.min(minV.Y, corner.Y),
                                math.min(minV.Z, corner.Z)
                            )
                            maxV = Vector3.new(
                                math.max(maxV.X, corner.X),
                                math.max(maxV.Y, corner.Y),
                                math.max(maxV.Z, corner.Z)
                            )
                        end
                    end
                end
            end
        end
    end
    if not minV or not maxV then
        local cf, size = model:GetBoundingBox()
        return cf.Position, size
    end
    return (minV + maxV) * 0.5, maxV - minV
end

local function frameBox(box: Model, viewport: ViewportFrame)
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    box.Parent = world

    local cam = Instance.new("Camera")
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    local _center0, size0 = getVisibleBounds(box)
    local h0 = math.max(size0.Y, 0.05)
    local factor = TARGET_HEIGHT / h0
    if math.abs(factor - 1) > 0.02 then
        pcall(function()
            box:ScaleTo(box:GetScale() * factor)
        end)
    end

    -- Slight yaw for 3/4 view (rotate around current pivot, then re-measure).
    local pivot = box:GetPivot()
    box:PivotTo(pivot * CFrame.Angles(0, math.rad(-28), 0))

    local center, size = getVisibleBounds(box)
    local extent = math.max(size.X, size.Y, size.Z, 0.5)
    local lookAt = center
    local dist = math.max(6.0, extent * 1.65)
    local camPos = lookAt + Vector3.new(extent * 0.45, extent * 0.22, dist)
    cam.CFrame = CFrame.lookAt(camPos, lookAt)
    cam.FieldOfView = 32
end

local function RewardCaseViewport(props: Props): React.Node
    local host, setHost = React.useState(nil :: ViewportFrame?)
    local mutKey = props.mutation or ""

    React.useEffect(function()
        if host == nil then
            return nil
        end
        for _, child in host:GetChildren() do
            child:Destroy()
        end

        local BoxModel = resolveBoxModel()
        if BoxModel == nil then
            warn("[RewardCaseViewport] BoxModel missing (Hoarcekat/Play path)")
            return nil
        end

        local muts = if props.mutation and props.mutation ~= "" then { props.mutation } else nil
        local box = BoxModel.clone(props.boxModelName, { mutations = muts })
        if box then
            frameBox(box, host)
        else
            warn(`[RewardCaseViewport] clone failed for {props.boxModelName}`)
        end

        return function()
            if host.Parent then
                for _, child in host:GetChildren() do
                    child:Destroy()
                end
            end
        end
    end, { host, props.boxModelName, mutKey } :: { any })

    return React.createElement("ViewportFrame", {
        Size = props.size,
        Position = props.position,
        AnchorPoint = props.anchorPoint,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(170, 170, 190),
        LightColor = Color3.fromRGB(255, 255, 255),
        LightDirection = Vector3.new(-0.4, -1, -0.5),
        ImageTransparency = if props.dimmed then 0.35 else 0,
        ZIndex = props.zIndex or 2,
        ref = function(rbx: ViewportFrame?)
            setHost(function(prev: ViewportFrame?)
                if prev == rbx then
                    return prev
                end
                return rbx
            end)
        end,
    })
end

return RewardCaseViewport
