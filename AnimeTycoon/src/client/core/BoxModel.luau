--!strict
-- Stands: Box1/2/3 orientation as cloned.
-- HeroPlace: same + align rotation to BoxHeroStand (debug prints kept).

local Workspace = game:GetService("Workspace")

local PlaceAlign = require(script.Parent.PlaceAlign)

local BoxModel = {}

-- Stands: Box1/2/3 orientation as cloned. Strip template Billboard; disable Highlight until Roll.
-- Ensure Roll-land Attachment (from Box3) exists on every clone.

local ROLL_LAND_ATTACHMENT = "Attachment"
local ROLL_LAND_EMIT_COUNT = 1

local function ensureRollLandAttachment(clone: Model)
    local box3 = Workspace:FindFirstChild("Box3")
    local src = box3 and box3:FindFirstChild(ROLL_LAND_ATTACHMENT)
    if not src then
        return
    end
    -- Always refresh from Box3 so Studio effect swaps are picked up (not stale Shockwave).
    local existing = clone:FindFirstChild(ROLL_LAND_ATTACHMENT)
    if existing then
        existing:Destroy()
    end
    local att = src:Clone()
    att.Name = ROLL_LAND_ATTACHMENT
    att.Parent = clone
    for _, d in att:GetDescendants() do
        if d:IsA("ParticleEmitter") then
            d.Rate = 0
            d.Enabled = true
        end
    end
end

local function prepareClone(template: Model, name: string): Model
    local clone = template:Clone()
    clone.Name = name
    local bb = clone:FindFirstChildWhichIsA("BillboardGui", true)
    if bb then
        bb:Destroy()
    end
    local hl = clone:FindFirstChildWhichIsA("Highlight")
    if hl then
        hl.Enabled = false
    end
    ensureRollLandAttachment(clone)
    for _, d in clone:GetDescendants() do
        if d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.Massless = true
        elseif d:IsA("ParticleEmitter") then
            d.Rate = 0
            d.Enabled = true
        end
    end
    -- Do NOT set PrimaryPart — it remaps GetPivot() and tips the box on its side.
    -- Do NOT ScaleTo(1): templates are authored at ~0.11 scale.
    return clone
end

local function dumpPose(label: string, model: Model)
    local pivot = model:GetPivot()
    local _bbCf, bbSize = model:GetBoundingBox()
    local rx, ry, rz = pivot:ToOrientation()
    local cube = model:FindFirstChildWhichIsA("BasePart", true)
    local vert = bbSize.Y >= bbSize.X and bbSize.Y >= bbSize.Z
    print(
        string.format(
            "[BoxPlaceDebug] %s | pos=(%.2f, %.2f, %.2f) | eulerDeg=(%.1f, %.1f, %.1f) | look=%s | up=%s | bb=%.2f,%.2f,%.2f | vert=%s | cubeOri=%s | parent=%s",
            label,
            pivot.Position.X,
            pivot.Position.Y,
            pivot.Position.Z,
            math.deg(rx),
            math.deg(ry),
            math.deg(rz),
            tostring(pivot.LookVector),
            tostring(pivot.UpVector),
            bbSize.X,
            bbSize.Y,
            bbSize.Z,
            tostring(vert),
            if cube then tostring(cube.Orientation) else "?",
            if model.Parent then model.Parent:GetFullName() else "nil"
        )
    )
end

local function dumpCompare(label: string, model: Model, reference: Model?)
    dumpPose(label, model)
    if not reference then
        print("[BoxPlaceDebug]   REF missing (BoxHeroStand)")
        return
    end
    local a = model:GetPivot()
    local b = reference:GetPivot()
    local arx, ary, arz = a:ToOrientation()
    local brx, bry, brz = b:ToOrientation()
    local _acf, aSize = model:GetBoundingBox()
    local _bcf, bSize = reference:GetBoundingBox()
    print(
        string.format(
            "[BoxPlaceDebug]   VS BoxHeroStand | deltaEulerDeg=(%.1f, %.1f, %.1f) | lookDot=%.3f | upDot=%.3f | bbDelta=(%.2f, %.2f, %.2f)",
            math.deg(arx - brx),
            math.deg(ary - bry),
            math.deg(arz - brz),
            a.LookVector:Dot(b.LookVector),
            a.UpVector:Dot(b.UpVector),
            aSize.X - bSize.X,
            aSize.Y - bSize.Y,
            aSize.Z - bSize.Z
        )
    )
    dumpPose("  REF BoxHeroStand", reference)
end

-- Must be parented before GetPivot/PivotTo or WorldPivot is wrong.
local function ensureWorldParent(model: Model)
    if model.Parent == nil then
        model.Parent = Workspace
    end
end

function BoxModel.clone(boxModelName: string): Model?
    local template = Workspace:FindFirstChild(boxModelName)
    if not template or not template:IsA("Model") then
        template = Workspace:FindFirstChild("Box1")
    end
    if not template or not template:IsA("Model") then
        return nil
    end
    return prepareClone(template, "ContainerVisual")
end

function BoxModel.emitRollLand(model: Model, count: number?)
    local att = model:FindFirstChild(ROLL_LAND_ATTACHMENT)
    if not att then
        return
    end
    local n = count or ROLL_LAND_EMIT_COUNT
    for _, d in att:GetDescendants() do
        if d:IsA("ParticleEmitter") then
            d:Emit(n)
        end
    end
end

-- Collect every pad emitter first, then Emit in one burst (same frame, synced).
function BoxModel.emitRollLandAll(models: { [number]: Model }, count: number?)
    local n = count or ROLL_LAND_EMIT_COUNT
    local emitters: { ParticleEmitter } = {}
    for _, model in models do
        local att = model:FindFirstChild(ROLL_LAND_ATTACHMENT)
        if att then
            for _, d in att:GetDescendants() do
                if d:IsA("ParticleEmitter") then
                    table.insert(emitters, d)
                end
            end
        end
    end
    for _, emitter in emitters do
        emitter:Emit(n)
    end
end

-- Stands: keep Box template orientation.
function BoxModel.placeOn(model: Model, target: BasePart)
    ensureWorldParent(model)
    PlaceAlign.onPad(model, target, nil)
    model.Parent = target
end

-- HeroPlace: bought box mesh; rotation = BoxHeroStand (same as Stand flow + correct yaw).
function BoxModel.placeOnHeroStand(model: Model, target: BasePart)
    local hs = Workspace:FindFirstChild("BoxHeroStand")
    local hsModel = if hs and hs:IsA("Model") then hs else nil

    print("========== [BoxPlaceDebug] placeOnHeroStand BEGIN ==========")
    print(
        string.format(
            "[BoxPlaceDebug] target=%s pos=(%.2f, %.2f, %.2f) size=%s",
            target:GetFullName(),
            target.Position.X,
            target.Position.Y,
            target.Position.Z,
            tostring(target.Size)
        )
    )

    ensureWorldParent(model)
    dumpCompare("1_after_parent_Workspace (bought box)", model, hsModel)

    if hsModel then
        -- Keep position, take ONLY rotation from BoxHeroStand (not full PivotTo HS pose).
        local pos = model:GetPivot().Position
        model:PivotTo(CFrame.new(pos) * hsModel:GetPivot().Rotation)
        dumpCompare("2_after_HS_rotation_only", model, hsModel)
    else
        -- Fallback: +90° Y like Box→HS delta when template present in edit.
        local pivot = model:GetPivot()
        model:PivotTo(
            CFrame.new(pivot.Position) * pivot.Rotation * CFrame.Angles(0, math.rad(90), 0)
        )
        dumpCompare("2_after_+90Y_fallback", model, hsModel)
    end

    PlaceAlign.onPad(model, target, nil)
    dumpCompare("3_after_PlaceAlign", model, hsModel)

    model.Parent = target
    dumpCompare("4_after_Parent_PlacePart", model, hsModel)

    print("========== [BoxPlaceDebug] placeOnHeroStand END ==========")
end

return BoxModel
