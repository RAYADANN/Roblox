--!strict
-- Client-only land burst for Place*/Teleport particles.
-- Enabled is owned by the SERVER (PlotManager) — client Enabled=false is overwritten
-- by replication when Studio defaults are Enabled=true.

local IncubatorStandFx = {}

local LAND_EMIT_MAX = 3

local _burstDone: { [BasePart]: boolean } = {}

local function landEmit(emitter: ParticleEmitter)
    local count = if emitter.Rate >= 10
        then LAND_EMIT_MAX
        elseif emitter.Rate > 0 then 1
        else LAND_EMIT_MAX
    emitter:Emit(count)
end

local function forEachEmitterUnder(root: Instance, fn: (ParticleEmitter) -> ())
    for _, d in root:GetDescendants() do
        if d:IsA("ParticleEmitter") then
            fn(d)
        end
    end
end

local function prepareEggPlace(part: BasePart)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
end

local function findEggPlacePart(tele: Instance): BasePart?
    local exact = tele:FindFirstChild("EggPlace")
    if exact and exact:IsA("BasePart") then
        return exact
    end
    local spaced = tele:FindFirstChild("Egg Place")
    if spaced and spaced:IsA("BasePart") then
        return spaced
    end
    for _, d in tele:GetDescendants() do
        if d:IsA("BasePart") and string.lower(d.Name) == "eggplace" then
            return d
        end
    end
    return nil
end

function IncubatorStandFx.findEggPlace(placeModel: Model): BasePart?
    local tele = placeModel:FindFirstChild("Teleport")
    if tele then
        local egg = findEggPlacePart(tele)
        if egg then
            prepareEggPlace(egg)
            return egg
        end
    end
    local stand = placeModel:FindFirstChild("Stand")
    if stand and stand:IsA("BasePart") then
        return stand
    end
    return nil
end

-- Soft Emit when an egg first lands (Enabled stays server-driven).
function IncubatorStandFx.onEggLanded(eggPlace: BasePart)
    if _burstDone[eggPlace] then
        return
    end
    _burstDone[eggPlace] = true
    local tele = eggPlace.Parent
    if not tele then
        return
    end
    forEachEmitterUnder(tele, landEmit)
end

function IncubatorStandFx.onEggCleared(eggPlace: BasePart)
    _burstDone[eggPlace] = nil
end

-- Burst-flag reset only. Enabled is server-owned — do not touch emitters here.
function IncubatorStandFx.disableAll()
    table.clear(_burstDone)
end

return IncubatorStandFx
