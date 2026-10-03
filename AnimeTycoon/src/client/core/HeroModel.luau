--!strict
-- Clone hero from ReplicatedStorage.GameAssets.Heroes (always replicated).
-- Fallback: ContentRoots.secret() (GameAssets.Stands.Secret).
-- Mutation FX: MutationFxAttach (scale to visible mesh bbox).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local ContentRoots = require(ReplicatedStorage.shared.util.ContentRoots)
local HeroCatalog = require(ReplicatedStorage.shared.data.HeroCatalog)
local HeroScaleLogic = require(ReplicatedStorage.shared.util.HeroScaleLogic)
local LimitedLogic = require(ReplicatedStorage.shared.util.LimitedLogic)
local MutationFxAttach = require(script.Parent.MutationFxAttach)
local MutationVisualDatabase = require(ReplicatedStorage.shared.data.MutationVisualDatabase)

export type CloneOpts = {
    rarity: string?,
    mutations: { string }?,
    mutationLabel: string?,
    --- ViewportFrame cannot render ParticleEmitters; add neon core for reveal UI.
    viewportSafe: boolean?,
    --- Normalize visual mesh height to this (studs). Default = pad height.
    targetHeight: number?,
    --- Optional max X/Y/Z after normalize.
    maxExtent: number?,
    --- Attach FX after caller places the hero (placeOn / reveal shot). Default false.
    deferMutationFx: boolean?,
    --- `limited_RobStandN` → clone authored Base.Limited stand mesh + baked VFX (no MutationFxAttach).
    templateId: string?,
}

local HeroModel = {}

-- Pending FX for deferMutationFx clones (weak keys).
local _pendingFx: { [Model]: {
    mutations: { string },
    viewportSafe: boolean?,
} } = setmetatable(
    {},
    { __mode = "k" }
) :: any

local function stripScripts(clone: Model)
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
end

local function normalizeName(name: string): string
    return string.lower((string.gsub(name, "[_%s%-]+", "")))
end

local function findInFolder(folder: Instance, heroId: string): Model?
    local exact = folder:FindFirstChild(heroId)
    if exact and exact:IsA("Model") then
        return exact
    end
    local want = normalizeName(heroId)
    for _, child in folder:GetChildren() do
        if child:IsA("Model") and normalizeName(child.Name) == want then
            return child
        end
    end
    return nil
end

local function searchHeroRoot(root: Instance, heroId: string, rarity: string?): Model?
    if rarity and rarity ~= "" then
        local folder = root:FindFirstChild(HeroCatalog.folderName(rarity))
        if folder then
            local hit = findInFolder(folder, heroId)
            if hit then
                return hit
            end
        end
    end
    for _, tier in root:GetChildren() do
        local hit = findInFolder(tier, heroId)
        if hit then
            return hit
        end
    end
    return nil
end

local function getTemplateRoots(): { Instance }
    local roots: { Instance } = {}
    local heroes = ContentRoots.heroes()
    if heroes then
        table.insert(roots, heroes)
    end
    return roots
end

local function findHeroTemplate(heroId: string?, rarity: string?): Model?
    if heroId and heroId ~= "" then
        for _, root in getTemplateRoots() do
            local hit = searchHeroRoot(root, heroId, rarity)
            if hit then
                return hit
            end
        end
        warn(`[HeroModel] hero "{heroId}" missing (rarity={rarity}) — using Secret`)
    elseif #getTemplateRoots() == 0 then
        warn("[HeroModel] GameAssets.Heroes missing — using Secret")
    end
    return ContentRoots.secret()
end

--- Authored Limited stand hero (mesh + VfxInstance), not Heroes remake.
local function findLimitedStandHero(standId: string, heroId: string?): Model?
    local limited = BaseLayout.getLimited()
    if not limited then
        return nil
    end
    local stand = limited:FindFirstChild(standId)
    if not stand then
        return nil
    end
    if heroId and heroId ~= "" then
        local named = findInFolder(stand, heroId)
        if named then
            return named
        end
    end
    -- Fallback: first MeshPart-bearing Model child (authored stand layout).
    for _, child in stand:GetChildren() do
        if child:IsA("Model") then
            for _, d in child:GetDescendants() do
                if d:IsA("MeshPart") or d:IsA("SpecialMesh") then
                    return child
                end
            end
        end
    end
    return nil
end

local function stripStandUi(clone: Model)
    for _, d in clone:GetDescendants() do
        if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
            d:Destroy()
        end
    end
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

--- World-space center + size of visible mesh only (ignores RootPart offset).
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
    local center = (minV + maxV) * 0.5
    local size = maxV - minV
    return CFrame.new(center), size
end

local function resolveMutations(opts: CloneOpts?): { string }?
    if not opts then
        return nil
    end
    return MutationFxAttach.resolveMutations(opts.mutations, opts.mutationLabel)
end

--- Attach / re-attach mutation FX (visual-center, HERO_FX_SCALE). Same as preview.
function HeroModel.applyMutationFx(model: Model, mutations: { string }?, viewportSafe: boolean?)
    local muts = mutations
    if not muts or #muts == 0 then
        local pending = _pendingFx[model]
        if pending then
            muts = pending.mutations
            if viewportSafe == nil then
                viewportSafe = pending.viewportSafe
            end
            _pendingFx[model] = nil
        end
    end
    if not muts or #muts == 0 then
        return
    end
    MutationFxAttach.apply(model, muts, {
        targetScale = MutationVisualDatabase.HERO_FX_SCALE,
        viewportSafe = viewportSafe,
    })
end

function HeroModel.getVisualBounds(model: Model): (CFrame, Vector3)
    return getVisualBounds(model)
end

--[[
  Parent hero into a ViewportFrame WorldModel and frame camera on feet baseline
  (same shot as HeroReveal). Returns faceYaw + feetY.
]]
function HeroModel.frameInViewport(
    hero: Model,
    viewport: ViewportFrame,
    yawBiasRad: number?
): (number, number)
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    hero.Parent = world

    local cam = Instance.new("Camera")
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    local pivot0 = hero:GetPivot()
    hero:PivotTo(CFrame.new(pivot0.Position))
    local _, visSize = getVisualBounds(hero)
    local height = math.max(visSize.Y, 0.5)
    local extent = math.max(visSize.X, height, visSize.Z, 0.5)

    local feetY = -height * 0.42
    local lookAt = Vector3.new(0, feetY + height * 0.52, 0)
    local dist = math.max(5.0, extent * 2.25)
    local camPos = lookAt + Vector3.new(0, height * 0.02, dist)
    cam.CFrame = CFrame.lookAt(camPos, lookAt)
    cam.FieldOfView = 30

    local faceTarget = Vector3.new(camPos.X, lookAt.Y, camPos.Z)
    local faceCf = CFrame.lookAt(lookAt, faceTarget)
    local _rx, faceYaw, _rz = faceCf:ToOrientation()
    local yaw = faceYaw + (yawBiasRad or 0)

    hero:PivotTo(CFrame.new(0, feetY, 0) * CFrame.Angles(0, yaw, 0))
    return yaw, feetY
end

--- Fit visual mesh to target height (authored ScaleTo varies 0.08…2.5+).
function HeroModel.normalizeSize(model: Model, targetHeight: number, maxExtent: number?)
    local _, size = getVisualBounds(model)
    local factor =
        HeroScaleLogic.factor({ X = size.X, Y = size.Y, Z = size.Z }, targetHeight, maxExtent)
    if math.abs(factor - 1) < 0.01 then
        return
    end
    local ok = pcall(function()
        model:ScaleTo(model:GetScale() * factor)
    end)
    if not ok then
        warn("[HeroModel] ScaleTo failed during normalize")
    end
end

function HeroModel.clone(heroId: string?, _legacyScale: number?, opts: CloneOpts?): Model?
    local rarity = if opts then opts.rarity else nil
    local templateId = if opts then opts.templateId else nil
    local standId = LimitedLogic.standIdFromTemplateId(templateId)
    local fromLimited = false
    local template: Model? = nil
    if standId then
        template = findLimitedStandHero(standId, heroId)
        fromLimited = template ~= nil
        if not template then
            warn(`[HeroModel] Limited stand hero missing {standId}/{heroId} — catalog fallback`)
        end
    end
    if not template then
        template = findHeroTemplate(heroId, rarity)
    end
    if not template then
        warn("[HeroModel] no template for", heroId, rarity)
        return nil
    end
    local clone = template:Clone()
    clone.Name = "HeroVisual"
    stripScripts(clone)
    if fromLimited then
        stripStandUi(clone)
    end

    local targetHeight = HeroScaleLogic.PAD_HEIGHT
    local maxExtent: number? = HeroScaleLogic.PAD_MAX_EXTENT
    if opts then
        if typeof(opts.targetHeight) == "number" then
            targetHeight = opts.targetHeight :: number
        end
        if opts.maxExtent ~= nil then
            maxExtent = opts.maxExtent
        end
    end
    HeroModel.normalizeSize(clone, targetHeight, maxExtent)

    -- Limited stands ship baked VfxInstance; do not layer MutationFxAttach on top.
    if not fromLimited then
        local muts = resolveMutations(opts)
        local deferFx = opts ~= nil and opts.deferMutationFx == true
        local viewportSafe = if opts then opts.viewportSafe else nil
        if muts and #muts > 0 then
            if deferFx then
                _pendingFx[clone] = { mutations = muts, viewportSafe = viewportSafe }
            else
                HeroModel.applyMutationFx(clone, muts, viewportSafe)
            end
        end
    end
    return clone
end

--- Place on pad by model origin (WorldPivot), not visual-bounds bottom.
--- Origin at pad top, then lowered by pad.Size.Y (1-stud cube → Y - 1).
--- Then mutation FX → visual mesh center (Preview_GalaxyAll path).
function HeroModel.placeOn(model: Model, target: BasePart)
    local yaw = math.rad(270) -- face opposite pad direction (was 90, +180)
    if target.Position.X >= 64 then
        yaw += math.rad(180)
    end
    -- Parent first so WorldPivot writes stick; then snap origin to pad top - Size.Y.
    model.Parent = target
    local padTopY = target.Position.Y + target.Size.Y * 0.5
    local origin = Vector3.new(target.Position.X, padTopY - target.Size.Y, target.Position.Z)
    model:PivotTo(CFrame.new(origin) * CFrame.Angles(0, yaw, 0))

    -- Prefer attach-after-place (correct visual center once feet are planted).
    if _pendingFx[model] then
        HeroModel.applyMutationFx(model, nil, nil)
    elseif model:FindFirstChild("MutationFx") then
        MutationFxAttach.recenter(model)
    end
end

return HeroModel
