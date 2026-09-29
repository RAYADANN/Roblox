--!strict
-- Index card ViewportFrame for scene pets (Workspace.Folder / ReplicatedStorage.Pets).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type Props = {
    modelName: string,
    unlocked: boolean,
}

local VIEW_SMALLER = 1.35
local LOCK_FILL = Color3.new(0, 0, 0)
local LOCK_OUTLINE = Color3.new(1, 1, 1)
local LOCK_OUTLINE_SCALE = 1.08

local function asModel(inst: Instance?): Model?
    if inst and inst:IsA("Model") then
        return inst
    end
    if inst and (inst:IsA("Folder") or inst:IsA("Model")) then
        local nested = inst:FindFirstChildWhichIsA("Model", true)
        if nested then
            return nested
        end
    end
    return nil
end

local function findTemplate(modelName: string): Model?
    local pets = ReplicatedStorage:FindFirstChild("Pets")
    if pets then
        local found = asModel(pets:FindFirstChild(modelName))
        if found then
            return found
        end
    end

    local folder = Workspace:FindFirstChild("Folder")
    if folder then
        local found = asModel(folder:FindFirstChild(modelName))
        if found then
            return found
        end
    end

    return nil
end

local function stripForViewport(model: Model)
    for _, inst in model:GetDescendants() do
        if inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            inst:Destroy()
        elseif inst:IsA("Script") or inst:IsA("LocalScript") then
            inst.Disabled = true
        elseif inst:IsA("BasePart") then
            inst.Anchored = true
            inst.CanCollide = false
            inst.CanQuery = false
            inst.CanTouch = false
            inst.Massless = true
        elseif inst:IsA("Humanoid") then
            inst.WalkSpeed = 0
            inst.JumpPower = 0
            inst.AutoRotate = false
            inst.PlatformStand = true
            inst.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            inst.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        elseif inst:IsA("Highlight") then
            inst.Enabled = false
        end
    end
end

local function applySolidColor(model: Model, color: Color3, material: Enum.Material)
    for _, inst in model:GetDescendants() do
        if inst:IsA("BasePart") then
            inst.Color = color
            inst.Material = material
            if inst:IsA("MeshPart") then
                inst.TextureID = ""
            end
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            inst.Transparency = 1
        elseif inst:IsA("SpecialMesh") then
            inst.TextureId = ""
        end
    end
end

local function makeViewport(parent: Frame, zIndex: number): ViewportFrame
    local frame = Instance.new("ViewportFrame")
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Ambient = Color3.fromRGB(186, 186, 198)
    frame.LightColor = Color3.fromRGB(255, 255, 255)
    frame.LightDirection = Vector3.new(-0.6, -1, -0.45)
    frame.ZIndex = zIndex
    frame.Parent = parent
    return frame
end

local function mountModel(worldParent: Instance, template: Model): Model
    local world = Instance.new("WorldModel")
    world.Parent = worldParent
    local clone = template:Clone()
    stripForViewport(clone)
    clone:PivotTo(CFrame.Angles(0, math.pi, 0))
    clone.Parent = world
    return clone
end

local function aimCamera(camera: Camera, model: Model)
    local cf, size = model:GetBoundingBox()
    local longest = math.max(size.X, size.Y, size.Z)
    local dist = math.max(longest * 1.35, 2) * VIEW_SMALLER
    local lookAt = cf.Position
    camera.CFrame =
        CFrame.lookAt(lookAt + Vector3.new(dist * 0.45, size.Y * 0.12, dist * 0.9), lookAt)
    camera.FieldOfView = 30
end

local function attachCamera(frame: ViewportFrame, model: Model, cameraCf: CFrame?): Camera
    local camera = Instance.new("Camera")
    camera.Name = "PetCamera"
    camera.FieldOfView = 30
    camera.Parent = frame
    frame.CurrentCamera = camera
    if cameraCf then
        camera.CFrame = cameraCf
    else
        aimCamera(camera, model)
    end
    return camera
end

local function mountPet(host: Frame, modelName: string, unlocked: boolean)
    host:ClearAllChildren()

    local template = findTemplate(modelName)
    if template == nil then
        return
    end

    if not unlocked then
        local outlineFrame = makeViewport(host, 1)
        local outline = mountModel(outlineFrame, template)
        applySolidColor(outline, LOCK_OUTLINE, Enum.Material.Neon)
        outline:ScaleTo(outline:GetScale() * LOCK_OUTLINE_SCALE)
        local fillFrame = makeViewport(host, 2)
        local fill = mountModel(fillFrame, template)
        applySolidColor(fill, LOCK_FILL, Enum.Material.SmoothPlastic)
        local camera = attachCamera(fillFrame, fill)
        attachCamera(outlineFrame, outline, camera.CFrame)
        return
    end

    local fillFrame = makeViewport(host, 2)
    local fill = mountModel(fillFrame, template)
    attachCamera(fillFrame, fill)
end

local function PetViewport(props: Props): React.Node
    local L = theme.Layout.index
    local hostRef = React.useRef(nil :: Frame?)

    React.useEffect(function()
        local host = hostRef.current
        if host == nil then
            return
        end
        mountPet(host, props.modelName, props.unlocked)
        return function()
            if host.Parent ~= nil then
                host:ClearAllChildren()
            end
        end
    end, { props.modelName, props.unlocked } :: { unknown })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(0.92, 1 - L.nameH - L.namePad - 0.04),
        Position = UDim2.fromScale(0.5, 0.04),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
        ref = hostRef,
    })
end

return PetViewport
