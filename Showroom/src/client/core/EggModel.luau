--!strict
-- Clone egg Models from Workspace.Eggs (skip Noname). Do not mutate mesh/transparency art.
-- Scale only via Model:ScaleTo — template Part/meshes stay proportional.
-- If template has no Part named "Part", create one from the mesh AABB (once at clone).

local Workspace = game:GetService("Workspace")

local EggModel = {}

local FOLDER_NAME = "Eggs"
local SKIP = {
    noname = true,
}
local FALLBACK_SIZE = Vector3.new(1.96, 2.48, 1.96)
local ATTR_VARIANT = "EggVariant"
local ATTR_REST_SCALE = "EggRestScale"
local ATTR_ORIG_T = "EggOrigTransparency"
local FX_PART_NAME = "Part"
local DEBUG_SHOW_FX_PART = false

local _variantNames: { string }? = nil

local function isSkipped(name: string): boolean
    return SKIP[string.lower(name)] == true
end

local function eggsFolder(): Instance?
    local folder = Workspace:FindFirstChild(FOLDER_NAME)
    if folder and (folder:IsA("Folder") or folder:IsA("Model")) then
        return folder
    end
    return nil
end

local function listVariantNames(): { string }
    if _variantNames then
        return _variantNames
    end
    local names: { string } = {}
    local folder = eggsFolder()
    if folder then
        for _, child in folder:GetChildren() do
            if child:IsA("Model") and not isSkipped(child.Name) then
                table.insert(names, child.Name)
            end
        end
        table.sort(names)
    end
    _variantNames = names
    return names
end

local function hashKey(key: string): number
    local h = 0
    for i = 1, #key do
        h = (h * 31 + string.byte(key, i)) % 2147483647
    end
    return h
end

function EggModel.variantForKey(key: string): string
    local names = listVariantNames()
    if #names == 0 then
        return "Standart"
    end
    local idx = (hashKey(key) % #names) + 1
    return names[idx]
end

local function findTemplate(variantName: string): Model?
    local folder = eggsFolder()
    if not folder then
        return nil
    end
    local m = folder:FindFirstChild(variantName)
    if m and m:IsA("Model") and not isSkipped(m.Name) then
        return m
    end
    return nil
end

local function styleFxPart(part: BasePart)
    if DEBUG_SHOW_FX_PART then
        part.Transparency = 0.45
        part.Color = Color3.fromRGB(0, 255, 255)
        part.Material = Enum.Material.Neon
    else
        part.Transparency = 1
    end
    part.CastShadow = false
end

-- Only the dedicated FX Part (never a MeshPart).
local function findFxPart(model: Model): Part?
    local named = model:FindFirstChild(FX_PART_NAME)
    if named and named:IsA("Part") then
        return named
    end
    for _, d in model:GetDescendants() do
        if d:IsA("Part") and d.Name == FX_PART_NAME then
            return d
        end
    end
    return nil
end

local function meshBounds(model: Model): (CFrame, Vector3)
    local ok, cf, size = pcall(function()
        return model:GetBoundingBox()
    end)
    if ok and typeof(cf) == "CFrame" and typeof(size) == "Vector3" and size.Magnitude > 0.01 then
        return cf, size
    end
    return CFrame.new(), FALLBACK_SIZE
end

-- Ensure a Part named "Part" exists. Templates currently only have MeshParts.
local function ensureFxPart(model: Model): Part
    local existing = findFxPart(model)
    if existing then
        styleFxPart(existing)
        return existing
    end

    local boxCf, boxSize = meshBounds(model)
    local part = Instance.new("Part")
    part.Name = FX_PART_NAME
    part.Size = boxSize
    part.CFrame = boxCf
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    styleFxPart(part)
    part.Parent = model
    return part
end

-- Physics flags only. Do not mutate mesh art.
local function prepareCloneParts(model: Model)
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false
            d.Massless = true
        end
    end
end

function EggModel.primary(model: Model): BasePart?
    return findFxPart(model)
end

function EggModel.extentsY(model: Model): number
    local fx = findFxPart(model)
    if fx then
        return fx.Size.Y
    end
    local _cf, size = meshBounds(model)
    return size.Y
end

-- Proportional scale of the whole template (meshes + Part together).
function EggModel.applyScale(model: Model, scale: number)
    local rest = model:GetAttribute(ATTR_REST_SCALE)
    local restScale = if typeof(rest) == "number" and rest > 0 then rest else model:GetScale()
    local s = math.max(scale, 0.05)
    pcall(function()
        model:ScaleTo(restScale * s)
    end)
    local fx = findFxPart(model)
    if fx then
        styleFxPart(fx)
    end
end

-- Position only. Orientation always 0 (same as upright Workspace eggs).
function EggModel.cfOnSurface(model: Model, surfaceCf: CFrame): CFrame
    local height = EggModel.extentsY(model)
    local pos = (surfaceCf * CFrame.new(0, height * 0.5 + 0.05, 0)).Position
    return CFrame.new(pos)
end

function EggModel.pivotOn(model: Model, surfaceCf: CFrame, yawOffset: CFrame?)
    local cf = EggModel.cfOnSurface(model, surfaceCf)
    if yawOffset then
        cf = cf * yawOffset
    end
    model:PivotTo(cf)
end

function EggModel.setVisible(model: Model, visible: boolean)
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            if d:IsA("Part") and d.Name == FX_PART_NAME then
                styleFxPart(d)
                continue
            end
            if visible then
                local orig = d:GetAttribute(ATTR_ORIG_T)
                if typeof(orig) == "number" then
                    d.Transparency = orig
                end
            else
                if d:GetAttribute(ATTR_ORIG_T) == nil then
                    d:SetAttribute(ATTR_ORIG_T, d.Transparency)
                end
                d.Transparency = 1
            end
        end
    end
end

function EggModel.variantOf(model: Model): string
    local v = model:GetAttribute(ATTR_VARIANT)
    if typeof(v) == "string" then
        return v
    end
    return ""
end

-- variantKey → deterministic pick among Eggs/* except Noname.
function EggModel.clone(instanceName: string, variantKey: string): (Model, BasePart)
    local variant = EggModel.variantForKey(variantKey)
    local template = findTemplate(variant)

    local model: Model
    local primary: BasePart

    if template then
        model = template:Clone()
        model.PrimaryPart = nil
        prepareCloneParts(model)
        -- REST scale before creating Part so AABB matches template rest size.
        model:SetAttribute(ATTR_REST_SCALE, model:GetScale())
        primary = ensureFxPart(model)
    else
        model = Instance.new("Model")
        local part = Instance.new("Part")
        part.Name = FX_PART_NAME
        part.Size = FALLBACK_SIZE
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Massless = true
        styleFxPart(part)
        part.Parent = model
        primary = part
        model:SetAttribute(ATTR_REST_SCALE, 1)
    end

    model.Name = instanceName
    model:SetAttribute(ATTR_VARIANT, variant)
    return model, primary
end

return EggModel
