--!strict
-- Clone pet Models from Workspace.Animals/<EggVariant>/*.
-- Folder name matches Eggs/* (Alien, Magma, Ocean, Standart, …).
-- Scale only via Model:ScaleTo.

local Workspace = game:GetService("Workspace")

local AnimalModel = {}

local FOLDER_NAME = "Animals"
local ATTR_SPECIES = "AnimalSpecies"
local ATTR_EGG_VARIANT = "AnimalEggVariant"
local ATTR_REST_SCALE = "AnimalRestScale"
local ATTR_ORIG_T = "AnimalOrigTransparency"
local FX_PART_NAME = "Part"
local FALLBACK_SIZE = Vector3.new(2, 2, 2)

local function animalsRoot(): Instance?
    local folder = Workspace:FindFirstChild(FOLDER_NAME)
    if folder and (folder:IsA("Folder") or folder:IsA("Model")) then
        return folder
    end
    return nil
end

local function hashKey(key: string): number
    local h = 0
    for i = 1, #key do
        h = (h * 31 + string.byte(key, i)) % 2147483647
    end
    return h
end

-- Merge all folders named eggVariant (Studio may have duplicate Standart folders).
local function listSpeciesTemplates(eggVariant: string): { Model }
    local root = animalsRoot()
    local out: { Model } = {}
    if not root then
        return out
    end
    local want = string.lower(eggVariant)
    for _, child in root:GetChildren() do
        if (child:IsA("Folder") or child:IsA("Model")) and string.lower(child.Name) == want then
            for _, m in child:GetChildren() do
                if m:IsA("Model") then
                    table.insert(out, m)
                end
            end
        end
    end
    table.sort(out, function(a, b)
        return a.Name < b.Name
    end)
    return out
end

function AnimalModel.speciesForKey(eggVariant: string, pickKey: string): string
    local templates = listSpeciesTemplates(eggVariant)
    if #templates == 0 then
        return ""
    end
    local idx = (hashKey(pickKey) % #templates) + 1
    return templates[idx].Name
end

local function findTemplate(eggVariant: string, speciesName: string): Model?
    local templates = listSpeciesTemplates(eggVariant)
    for _, m in templates do
        if m.Name == speciesName then
            return m
        end
    end
    return nil
end

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

local function ensureFxPart(model: Model): Part
    local existing = findFxPart(model)
    if existing then
        existing.Transparency = 1
        existing.CastShadow = false
        return existing
    end
    local boxCf, boxSize = meshBounds(model)
    local part = Instance.new("Part")
    part.Name = FX_PART_NAME
    part.Size = boxSize
    part.CFrame = boxCf
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.CastShadow = false
    part.Parent = model
    return part
end

local function prepareCloneParts(model: Model)
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false
            d.Massless = true
        elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") then
            d:Destroy()
        end
    end
end

function AnimalModel.primary(model: Model): BasePart?
    return findFxPart(model)
end

function AnimalModel.extentsY(model: Model): number
    local fx = findFxPart(model)
    if fx then
        return fx.Size.Y
    end
    local _cf, size = meshBounds(model)
    return size.Y
end

function AnimalModel.applyScale(model: Model, scale: number)
    local rest = model:GetAttribute(ATTR_REST_SCALE)
    local restScale = if typeof(rest) == "number" and rest > 0 then rest else model:GetScale()
    local s = math.max(scale, 0.05)
    pcall(function()
        model:ScaleTo(restScale * s)
    end)
end

function AnimalModel.cfOnSurface(model: Model, surfaceCf: CFrame): CFrame
    local height = AnimalModel.extentsY(model)
    local pos = (surfaceCf * CFrame.new(0, height * 0.5 + 0.05, 0)).Position
    return CFrame.new(pos)
end

function AnimalModel.setVisible(model: Model, visible: boolean)
    for _, d in model:GetDescendants() do
        if d:IsA("BasePart") then
            if d:IsA("Part") and d.Name == FX_PART_NAME then
                d.Transparency = 1
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

function AnimalModel.speciesOf(model: Model): string
    local v = model:GetAttribute(ATTR_SPECIES)
    if typeof(v) == "string" then
        return v
    end
    return ""
end

-- eggVariant = Eggs/* name; pickKey = exhibit uid (deterministic species).
function AnimalModel.clone(
    instanceName: string,
    eggVariant: string,
    pickKey: string
): (Model?, BasePart?)
    local species = AnimalModel.speciesForKey(eggVariant, pickKey)
    if species == "" then
        return nil, nil
    end
    local template = findTemplate(eggVariant, species)
    if not template then
        return nil, nil
    end

    local model = template:Clone()
    model.Name = instanceName
    model.PrimaryPart = nil
    prepareCloneParts(model)
    model:SetAttribute(ATTR_REST_SCALE, model:GetScale())
    model:SetAttribute(ATTR_SPECIES, species)
    model:SetAttribute(ATTR_EGG_VARIANT, eggVariant)
    local primary = ensureFxPart(model)
    return model, primary
end

return AnimalModel
