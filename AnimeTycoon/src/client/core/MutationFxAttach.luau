--!strict
-- Clone mutation FX part onto a host model (box or hero).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContentRoots = require(ReplicatedStorage.shared.util.ContentRoots)
local MutationVisualDatabase = require(ReplicatedStorage.shared.data.MutationVisualDatabase)

export type AttachOpts = {
    --- Max-axis scale vs host visual bbox (default HERO_FX_SCALE).
    targetScale: number?,
    --- ViewportFrame cannot render particles; add neon core.
    viewportSafe: boolean?,
}

local MutationFxAttach = {}

local function getFxBank(): Instance?
    return ContentRoots.mutationFx()
end

local function maxAxis(size: Vector3): number
    return math.max(size.X, size.Y, size.Z)
end

local function isHelperPart(part: BasePart): boolean
    local n = string.lower(part.Name)
    if part.Transparency >= 0.99 then
        return true
    end
    if n == "mutationfx" or n == "mutationfxcore" then
        return true
    end
    if string.find(n, "root", 1, true) then
        return true
    end
    return false
end

local function getVisualBounds(model: Model): (CFrame, Vector3)
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
        return model:GetBoundingBox()
    end
    return CFrame.new((minV + maxV) * 0.5), maxV - minV
end

local function mutationCoreColor(mutationId: string): Color3
    if mutationId == "golden" then
        return Color3.fromRGB(255, 200, 60)
    elseif mutationId == "diamond" then
        return Color3.fromRGB(120, 220, 255)
    elseif mutationId == "secret" then
        return Color3.fromRGB(255, 60, 100)
    end
    return Color3.fromRGB(170, 80, 255)
end

function MutationFxAttach.mutationsFromLabel(mutationLabel: string): { string }
    local derived: { string } = {}
    for token in string.gmatch(string.lower(mutationLabel), "[a-z]+") do
        if MutationVisualDatabase.get(token) then
            table.insert(derived, token)
        end
    end
    return derived
end

function MutationFxAttach.resolveMutations(
    mutations: { string }?,
    mutationLabel: string?
): { string }?
    if mutations and #mutations > 0 then
        return mutations
    end
    if typeof(mutationLabel) == "string" and mutationLabel ~= "" then
        local derived = MutationFxAttach.mutationsFromLabel(mutationLabel)
        if #derived > 0 then
            return derived
        end
    end
    return nil
end

function MutationFxAttach.apply(host: Model, mutations: { string }?, opts: AttachOpts?)
    local def = MutationVisualDatabase.resolveFromStack(mutations)
    if not def then
        return
    end
    local bank = getFxBank()
    local effectModel = bank and bank:FindFirstChild(def.effectModelName)
    if not effectModel then
        warn(`[MutationFxAttach] bank.{def.effectModelName} missing`)
        return
    end
    local srcPart: BasePart? = nil
    for _, partName in def.effectPartNames do
        local p = effectModel:FindFirstChild(partName)
        if p and p:IsA("BasePart") then
            srcPart = p
            break
        end
        local deep = effectModel:FindFirstChild(partName, true)
        if deep and deep:IsA("BasePart") then
            srcPart = deep
            break
        end
    end
    if not srcPart then
        warn(`[MutationFxAttach] FX part missing for {def.mutationId}`)
        return
    end

    local existing = host:FindFirstChild("MutationFx")
    if existing then
        existing:Destroy()
    end
    local existingCore = host:FindFirstChild("MutationFxCore")
    if existingCore then
        existingCore:Destroy()
    end

    local fx = srcPart:Clone()
    fx.Name = "MutationFx"
    fx.Anchored = true
    fx.CanCollide = false
    fx.CanQuery = false
    fx.CanTouch = false
    fx.Massless = true
    fx.Transparency = 1
    fx.CastShadow = false

    for _, d in fx:GetDescendants() do
        if d:IsA("WeldConstraint") or d:IsA("Weld") or d:IsA("Motor6D") then
            d:Destroy()
        end
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.Massless = true
        elseif d:IsA("ParticleEmitter") then
            d.Enabled = true
            if d.Rate <= 0 then
                d.Rate = math.max(d.Rate, 8)
            end
        end
    end

    local visualCf, hostSize = getVisualBounds(host)
    local hostAxis = maxAxis(hostSize)
    local fxAxis = maxAxis(fx.Size)
    local scaleMult = (opts and opts.targetScale) or MutationVisualDatabase.HERO_FX_SCALE
    if fxAxis > 0.05 and hostAxis > 0.05 then
        local factor = (hostAxis * scaleMult) / fxAxis
        fx.Size = fx.Size * factor
        for _, d in fx:GetDescendants() do
            if d:IsA("BasePart") and d ~= fx then
                d.Size = d.Size * factor
            end
        end
    end

    local _, yaw, _ = host:GetPivot():ToOrientation()
    local at = CFrame.new(visualCf.Position) * CFrame.Angles(0, yaw, 0)
    fx.CFrame = at
    fx.Parent = host

    if opts and opts.viewportSafe then
        local core = Instance.new("Part")
        core.Name = "MutationFxCore"
        core.Shape = Enum.PartType.Ball
        core.Material = Enum.Material.Neon
        core.Color = mutationCoreColor(def.mutationId)
        core.Size = Vector3.new(1, 1, 1) * math.max(0.35, hostAxis * 0.22)
        core.Transparency = 0.35
        core.Anchored = true
        core.CanCollide = false
        core.CanQuery = false
        core.CanTouch = false
        core.CastShadow = false
        core.Massless = true
        core.CFrame = at
        core.Parent = host
    end
end

function MutationFxAttach.recenter(host: Model)
    local visualCf, _ = getVisualBounds(host)
    local _, yaw, _ = host:GetPivot():ToOrientation()
    local at = CFrame.new(visualCf.Position) * CFrame.Angles(0, yaw, 0)
    for _, name in { "MutationFx", "MutationFxCore" } do
        local fx = host:FindFirstChild(name)
        if fx and fx:IsA("BasePart") then
            fx.CFrame = at
        end
    end
end

return MutationFxAttach
