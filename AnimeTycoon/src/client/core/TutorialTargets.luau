--!strict
-- Resolve FTUE world targets from Base markers + live offer/slot visuals.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)
local RampWorldRenderer = require(script.Parent.RampWorldRenderer)
local StandPromptBinder = require(script.Parent.StandPromptBinder)

local TutorialTargets = {}

--- Largest visible MeshPart under a model (skip tiny FX / hidden).
local function largestVisibleMesh(inst: Instance): BasePart?
    local best: BasePart? = nil
    local bestScore = -1
    for _, d in inst:GetDescendants() do
        if d:IsA("BasePart") and d.Transparency < 0.95 and d.LocalTransparencyModifier < 0.95 then
            local vol = d.Size.X * d.Size.Y * d.Size.Z
            if vol < 0.08 then
                continue
            end
            local score = if d:IsA("MeshPart") then vol * 10 else vol
            if score > bestScore then
                bestScore = score
                best = d
            end
        end
    end
    return best
end

local function preferVisualPart(inst: Instance?): BasePart?
    if inst == nil then
        return nil
    end
    if inst:IsA("MeshPart") then
        return inst
    end
    if inst:IsA("BasePart") then
        return inst
    end
    return largestVisibleMesh(inst)
end

local function decodeArray(json: string): { any }
    if json == "" then
        return {}
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    if ok and typeof(decoded) == "table" then
        return decoded
    end
    return {}
end

--- Roll: exact Button MeshPart under RollButton.
function TutorialTargets.roll(): Instance?
    local stands = BaseLayout.getStands()
    if not stands then
        return nil
    end
    local roll = stands:FindFirstChild("RollButton")
    if not roll then
        return nil
    end
    local button = roll:FindFirstChild("Button")
    if button and button:IsA("BasePart") then
        return button
    end
    return preferVisualPart(roll)
end

--- Buy: live box mesh on Stand1 (not the pad).
function TutorialTargets.buy(_offersJson: string): Instance?
    local model = StandPromptBinder.getOfferModel(1)
    if model and model.Parent then
        local mesh = largestVisibleMesh(model)
        if mesh then
            return mesh
        end
        return model
    end
    local stands = BaseLayout.getStands()
    if not stands then
        return nil
    end
    local stand = stands:FindFirstChild("Stand1")
    if not stand then
        return nil
    end
    local pad = stand:FindFirstChild("BoxPlace") or stand:FindFirstChild("EggPlace")
    return preferVisualPart(pad) or stand
end

--- Place: Cube.001 on the empty HeroPlace button.
local function heroPlaceCube(placePart: BasePart): BasePart?
    local button = placePart.Parent
    if not button then
        return nil
    end
    local cube = button:FindFirstChild("Cube.001")
    if cube and cube:IsA("BasePart") then
        return cube
    end
    return nil
end

function TutorialTargets.place(slotsJson: string): Instance?
    local occupied: { [number]: boolean } = {}
    for _, row in decodeArray(slotsJson) do
        if typeof(row) == "table" and typeof(row.slotIndex) == "number" then
            occupied[row.slotIndex] = true
        end
    end
    for i, part in HeroPlaceLayout.getOrderedPlaceParts() do
        if not occupied[i] then
            return heroPlaceCube(part) or part
        end
    end
    local first = HeroPlaceLayout.getOrderedPlaceParts()[1]
    if first then
        return heroPlaceCube(first) or first
    end
    return nil
end

local function firstSlotIndex(slotsJson: string, predicate: (row: any) -> boolean): number?
    for _, row in decodeArray(slotsJson) do
        if typeof(row) == "table" and typeof(row.slotIndex) == "number" and predicate(row) then
            return row.slotIndex
        end
    end
    return nil
end

function TutorialTargets.waitReady(slotsJson: string): Instance?
    local idx = firstSlotIndex(slotsJson, function(row)
        return row.unpacked ~= true
    end) or 1
    return RampWorldRenderer.getLocalSlotAttachPart(idx)
        or HeroPlaceLayout.getOrderedPlaceParts()[idx]
end

function TutorialTargets.open(slotsJson: string): Instance?
    local readyIdx = firstSlotIndex(slotsJson, function(row)
        return row.unpacked ~= true and (tonumber(row.unpackProgress) or 0) >= 0.999
    end)
    local packingIdx = firstSlotIndex(slotsJson, function(row)
        return row.unpacked ~= true
    end)
    local anyIdx = firstSlotIndex(slotsJson, function(_row)
        return true
    end)
    local idx = readyIdx or packingIdx or anyIdx or 1
    return RampWorldRenderer.getLocalSlotAttachPart(idx)
        or HeroPlaceLayout.getOrderedPlaceParts()[idx]
end

function TutorialTargets.waitPath(): Instance?
    return BaseLayout.getSellBox()
end

function TutorialTargets.take(): Instance?
    return BaseLayout.getSellBox()
end

function TutorialTargets.sell(): Instance?
    return BaseLayout.getSellGuy()
end

function TutorialTargets.resolve(
    targetKind: string,
    offersJson: string,
    slotsJson: string
): Instance?
    if targetKind == "roll" then
        return TutorialTargets.roll()
    elseif targetKind == "buy" then
        return TutorialTargets.buy(offersJson)
    elseif targetKind == "place" then
        return TutorialTargets.place(slotsJson)
    elseif targetKind == "wait_ready" then
        return TutorialTargets.waitReady(slotsJson)
    elseif targetKind == "open" then
        return TutorialTargets.open(slotsJson)
    elseif targetKind == "wait_path" then
        return TutorialTargets.waitPath()
    elseif targetKind == "take" then
        return TutorialTargets.take()
    elseif targetKind == "sell" then
        return TutorialTargets.sell()
    end
    return nil
end

function TutorialTargets.anchorPart(target: Instance?): BasePart?
    return preferVisualPart(target)
end

return TutorialTargets
