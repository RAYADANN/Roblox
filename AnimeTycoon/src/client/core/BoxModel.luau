--!strict
-- Stands: box orientation as cloned.
-- HeroPlace: same + align rotation to BoxHeroStand.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ContentRoots = require(ReplicatedStorage.shared.util.ContentRoots)
local MutationFxAttach = require(script.Parent.MutationFxAttach)
local MutationVisualDatabase = require(ReplicatedStorage.shared.data.MutationVisualDatabase)
local PlaceAlign = require(script.Parent.PlaceAlign)

local BoxModel = {}

export type CloneOpts = {
    mutations: { string }?,
    mutationLabel: string?,
}

local ROLL_LAND_ATTACHMENT = "Attachment"
local ROLL_LAND_EMIT_COUNT = 1

local function ensureRollLandAttachment(clone: Model)
    local src = ContentRoots.boxRollLandAttachment()
    if not src then
        return
    end
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
    return clone
end

local function ensureWorldParent(model: Model)
    if model.Parent == nil then
        model.Parent = Workspace
    end
end

function BoxModel.clone(boxModelName: string, opts: CloneOpts?): Model?
    local template: Model? = ContentRoots.findBoxModel(boxModelName)
    if not template then
        template = ContentRoots.findBoxModel("Box1")
    end
    if not template then
        local boxes = ContentRoots.boxes()
        if boxes then
            for _, shape in { "1", "2", "3" } do
                local folder = boxes:FindFirstChild(shape)
                if folder then
                    for _, child in folder:GetChildren() do
                        if child:IsA("Model") then
                            template = child
                            break
                        end
                    end
                end
                if template then
                    break
                end
            end
        end
    end
    if not template then
        return nil
    end
    local clone = prepareClone(template, "ContainerVisual")
    clone:SetAttribute("BoxTemplateName", template.Name)
    local tr = template:GetPivot().Rotation
    local rx, ry, rz = tr:ToOrientation()
    clone:SetAttribute("StandRestRx", rx)
    clone:SetAttribute("StandRestRy", ry)
    clone:SetAttribute("StandRestRz", rz)
    if opts then
        local muts = MutationFxAttach.resolveMutations(opts.mutations, opts.mutationLabel)
        if muts then
            MutationFxAttach.apply(clone, muts, {
                targetScale = MutationVisualDatabase.BOX_FX_SCALE,
            })
        end
    end
    return clone
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

function BoxModel.placeOn(model: Model, target: BasePart)
    ensureWorldParent(model)
    local rx = model:GetAttribute("StandRestRx")
    local ry = model:GetAttribute("StandRestRy")
    local rz = model:GetAttribute("StandRestRz")
    if typeof(rx) == "number" and typeof(ry) == "number" and typeof(rz) == "number" then
        local pos = model:GetPivot().Position
        model:PivotTo(CFrame.new(pos) * CFrame.Angles(rx :: number, ry :: number, rz :: number))
    end
    PlaceAlign.onPad(model, target, nil)
    MutationFxAttach.recenter(model)
    model.Parent = target
end

function BoxModel.placeOnHeroStand(model: Model, target: BasePart)
    local hsModel = ContentRoots.boxHeroStand()

    ensureWorldParent(model)

    if hsModel then
        local pos = model:GetPivot().Position
        model:PivotTo(CFrame.new(pos) * hsModel:GetPivot().Rotation)
    else
        local pivot = model:GetPivot()
        model:PivotTo(
            CFrame.new(pivot.Position) * pivot.Rotation * CFrame.Angles(0, math.rad(90), 0)
        )
    end

    PlaceAlign.onPad(model, target, nil)
    MutationFxAttach.recenter(model)
    model.Parent = target
end

return BoxModel
