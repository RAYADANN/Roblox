--!strict
-- Clone Workspace mutation MeshPart FX onto eggs/pets.
-- Templates: Shape=Box, ShapeStyle=Volume, LockedToPart — emission fills the host box.
-- Host.Size tracks the egg FX Part (Volume). Particle Size stays authored × polish
-- (absolute studs; do NOT also shrink by egg ratio or FX go tiny).

local ContentProvider = game:GetService("ContentProvider")
local Workspace = game:GetService("Workspace")

local MutationFx = {}

local ATTR = "MutationFx"
local HOST_NAME = "MutationFxHost"
local FX_SIZE_SCALE = 1.5
local FX_Z_OFFSET = 0
local APPEAR_EMIT_MIN = 6
local APPEAR_EMIT_MAX = 28

local _templatesReady = false
local _preloadStarted = false

local function titleCase(id: string): string
    if id == "" then
        return ""
    end
    return string.upper(string.sub(id, 1, 1)) .. string.lower(string.sub(id, 2))
end

local function scaleNumberSequence(seq: NumberSequence, mult: number): NumberSequence
    local keys = table.create(#seq.Keypoints)
    for i, kp in seq.Keypoints do
        keys[i] = NumberSequenceKeypoint.new(kp.Time, kp.Value * mult, kp.Envelope * mult)
    end
    return NumberSequence.new(keys)
end

local function prepareEmitter(emitter: ParticleEmitter)
    emitter.Size = scaleNumberSequence(emitter.Size, FX_SIZE_SCALE)
    emitter.ZOffset = FX_Z_OFFSET
    -- Authoring contract for egg FX templates.
    emitter.Shape = Enum.ParticleEmitterShape.Box
    emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    emitter.LockedToPart = true
end

local function appearEmit(emitter: ParticleEmitter)
    local rate = emitter.Rate
    local count = if rate > 0
        then math.clamp(math.ceil(rate * 0.45), APPEAR_EMIT_MIN, APPEAR_EMIT_MAX)
        else APPEAR_EMIT_MIN
    emitter:Emit(count)
end

local function forEachTemplateEmitter(fn: (ParticleEmitter) -> ())
    for _, child in Workspace:GetChildren() do
        if child:IsA("BasePart") then
            for _, d in child:GetDescendants() do
                if d:IsA("ParticleEmitter") then
                    fn(d)
                end
            end
        end
    end
end

local function ensureTemplatesHidden()
    if _templatesReady then
        return
    end
    _templatesReady = true
    for _, child in Workspace:GetChildren() do
        if child:IsA("BasePart") then
            local hasFx = false
            for _, d in child:GetDescendants() do
                if d:IsA("ParticleEmitter") then
                    hasFx = true
                    d.ZOffset = FX_Z_OFFSET
                end
            end
            if hasFx then
                child.Transparency = 0
                child.CanCollide = false
                child.CanQuery = false
                child.CanTouch = false
                child.CastShadow = false
                child.Anchored = true
            end
        end
    end
end

local function findTemplate(key: string): BasePart?
    local name = titleCase(key)
    local inst = Workspace:FindFirstChild(name)
    if inst and inst:IsA("BasePart") then
        return inst
    end
    local lower = string.lower(key)
    for _, child in Workspace:GetChildren() do
        if child:IsA("BasePart") and string.lower(child.Name) == lower then
            return child
        end
    end
    return nil
end

function MutationFx.preload()
    if _preloadStarted then
        return
    end
    _preloadStarted = true
    task.spawn(function()
        ensureTemplatesHidden()
        local assets: { Instance } = {}
        forEachTemplateEmitter(function(emitter)
            table.insert(assets, emitter)
        end)
        if #assets == 0 then
            return
        end
        local ok, err = pcall(function()
            ContentProvider:PreloadAsync(assets)
        end)
        if not ok then
            warn(`[MutationFx] preload failed: {err}`)
        end
    end)
end

function MutationFx.keysFromLabel(label: string): { string }
    local out: { string } = {}
    if label == "" then
        return out
    end
    for _, seg in string.split(label, "-") do
        if seg ~= "" then
            local id = string.lower(seg)
            if id ~= "giant" then
                table.insert(out, id)
            end
        end
    end
    return out
end

local function clear(target: BasePart)
    local parent = target.Parent
    if parent then
        local host = parent:FindFirstChild(HOST_NAME)
        if host and host:GetAttribute(ATTR) == true then
            host:Destroy()
        end
    end
    local nested = target:FindFirstChild(HOST_NAME)
    if nested and nested:GetAttribute(ATTR) == true then
        nested:Destroy()
    end
    for _, child in target:GetChildren() do
        if child:GetAttribute(ATTR) == true then
            child:Destroy()
        end
    end
end

local function ensureHost(target: BasePart): BasePart
    local existing = target:FindFirstChild(HOST_NAME)
    if existing and existing:IsA("BasePart") and existing:GetAttribute(ATTR) == true then
        existing.Size = target.Size
        existing.CFrame = target.CFrame
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local host = Instance.new("Part")
    host.Name = HOST_NAME
    host:SetAttribute(ATTR, true)
    host.Transparency = 1
    host.Anchored = false
    host.Massless = true
    host.CanCollide = false
    host.CanQuery = false
    host.CanTouch = false
    host.CastShadow = false
    host.Size = target.Size
    host.CFrame = target.CFrame
    host.Parent = target

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target
    weld.Part1 = host
    weld.Parent = host
    return host
end

local function cloneFxOnto(host: BasePart, template: BasePart)
    for _, child in template:GetChildren() do
        if child:IsA("ParticleEmitter") then
            local clone = child:Clone()
            clone:SetAttribute(ATTR, true)
            clone.Enabled = true
            prepareEmitter(clone)
            clone.Parent = host
            appearEmit(clone)
        elseif child:IsA("Attachment") then
            local att = child:Clone()
            att:SetAttribute(ATTR, true)
            att.Parent = host
            for _, d in att:GetDescendants() do
                if d:IsA("ParticleEmitter") then
                    d:SetAttribute(ATTR, true)
                    d.Enabled = true
                    prepareEmitter(d)
                    appearEmit(d)
                end
            end
        end
    end
end

function MutationFx.sync(target: BasePart, keys: { string })
    MutationFx.preload()
    ensureTemplatesHidden()
    clear(target)
    if #keys == 0 then
        return
    end
    local host = ensureHost(target)
    local seen: { [string]: boolean } = {}
    for _, key in keys do
        local id = string.lower(key)
        if not seen[id] then
            seen[id] = true
            local template = findTemplate(id)
            if template then
                cloneFxOnto(host, template)
            end
        end
    end
end

function MutationFx.syncFromLabel(target: BasePart, mutationLabel: string?)
    local label = if typeof(mutationLabel) == "string" then mutationLabel else ""
    MutationFx.sync(target, MutationFx.keysFromLabel(label))
end

function MutationFx.clear(target: BasePart)
    clear(target)
end

-- Volume = host box; keep host sized to the egg FX Part as it grows/shrinks.
function MutationFx.follow(target: BasePart)
    local host = target:FindFirstChild(HOST_NAME)
    if host and host:IsA("BasePart") and host:GetAttribute(ATTR) == true then
        if host.Size ~= target.Size then
            host.Size = target.Size
        end
    end
end

return MutationFx
