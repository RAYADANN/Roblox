--!strict
-- Minis: SpawnPartN → LeftSlideN/RightSlideN → Center → exit.
-- Path points = belt TOP; mini WorldPivot (origin/feet) sits on that surface.
-- Paths are per owner base (Base1..Base6).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BaseLayout = require(ReplicatedStorage.shared.util.BaseLayout)
local Constants = require(ReplicatedStorage.shared.data.Constants)
local HeroModel = require(script.Parent.HeroModel)
local HeroPlaceLayout = require(ReplicatedStorage.shared.util.HeroPlaceLayout)
local HeroScaleLogic = require(ReplicatedStorage.shared.util.HeroScaleLogic)
local SellBoxVisual = require(script.Parent.SellBoxVisual)

local ConveyorVisual = {}

local _folder: Folder? = nil
local _pathsByOwner: { [number]: { [number]: { Vector3 } } } = {}

local function ensureFolder(): Folder
    if _folder and _folder.Parent then
        return _folder
    end
    local existing = Workspace:FindFirstChild("ConveyorMinis")
    if existing and existing:IsA("Folder") then
        _folder = existing
        return existing
    end
    local f = Instance.new("Folder")
    f.Name = "ConveyorMinis"
    f.Parent = Workspace
    _folder = f
    return f
end

local function partsIn(folder: Instance?): { BasePart }
    local out: { BasePart } = {}
    if not folder then
        return out
    end
    for _, p in folder:GetChildren() do
        if p:IsA("BasePart") then
            table.insert(out, p)
        end
    end
    return out
end

--- World point on the top face of a belt part (origin sits here).
local function topPoint(part: BasePart, x: number?, z: number?): Vector3
    local topY = part.Position.Y + part.Size.Y * 0.5
    return Vector3.new(x or part.Position.X, topY, z or part.Position.Z)
end

local function nearestByZ(parts: { BasePart }, z: number): BasePart?
    local best: BasePart? = nil
    local bestDist = math.huge
    for _, p in parts do
        local d = math.abs(p.Position.Z - z)
        if d < bestDist then
            bestDist = d
            best = p
        end
    end
    return best
end

local function buildPathForSlot(
    place: BasePart,
    spawns: { BasePart },
    leftSlide: { BasePart },
    rightSlide: { BasePart },
    center: BasePart,
    midX: number
): { Vector3 }
    local sameLeft = place.Position.X < midX
    local lane = if sameLeft then leftSlide else rightSlide

    local leftSpawns: { BasePart } = {}
    local rightSpawns: { BasePart } = {}
    for _, s in spawns do
        if s.Position.X < midX then
            table.insert(leftSpawns, s)
        else
            table.insert(rightSpawns, s)
        end
    end
    local spawnPool = if sameLeft then leftSpawns else rightSpawns
    local spawn = nearestByZ(spawnPool, place.Position.Z)
    -- Rotated / mirrored plots: fall back to the full spawn list.
    if not spawn then
        spawn = nearestByZ(spawns, place.Position.Z)
    end
    if not spawn then
        -- Last resort: place → center row → center exit (always ≥2 points).
        local rowZ = place.Position.Z
        local halfZ = center.Size.Z * 0.5
        local exitXZ = center.Position - center.CFrame.LookVector * halfZ
        return {
            topPoint(place),
            topPoint(center, center.Position.X, rowZ),
            topPoint(center, exitXZ.X, exitXZ.Z),
        }
    end

    local slide = nearestByZ(lane, spawn.Position.Z)
    if not slide then
        slide = nearestByZ(if sameLeft then rightSlide else leftSlide, spawn.Position.Z)
    end
    local path: { Vector3 } = { topPoint(spawn) }
    if slide then
        table.insert(path, topPoint(slide))
    end

    local rowZ = if slide then slide.Position.Z else spawn.Position.Z
    table.insert(path, topPoint(center, center.Position.X, rowZ))

    local halfZ = center.Size.Z * 0.5
    local exitXZ = center.Position - center.CFrame.LookVector * halfZ
    table.insert(path, topPoint(center, exitXZ.X, exitXZ.Z))
    return path
end

local function buildPathsForOwner(ownerUserId: number): { [number]: { Vector3 } }
    local paths: { [number]: { Vector3 } } = {}
    local base = BaseLayout.getForUserId(ownerUserId)
    if not base then
        local lp = Players.LocalPlayer
        if lp and lp.UserId == ownerUserId then
            base = BaseLayout.getLocal()
        end
    end
    if not base then
        return paths
    end
    local primaryRamp = BaseLayout.getRamp(base)
    -- Resolve place parts from the base directly (don't depend on RampWorldRenderer cache).
    local placeParts = HeroPlaceLayout.getOrderedPlaceParts(base)

    for i, place in placeParts do
        if i > Constants.SLOT_COUNT then
            break
        end
        local ramp: Instance? = place:FindFirstAncestor("Ramp2")
            or place:FindFirstAncestor("Ramp3")
            or place:FindFirstAncestor("Ramp")
            or primaryRamp
        if not ramp then
            continue
        end
        local center = ramp:FindFirstChild("Center")
        if not center or not center:IsA("BasePart") then
            center = primaryRamp and primaryRamp:FindFirstChild("Center")
            ramp = primaryRamp
        end
        if not center or not center:IsA("BasePart") or not ramp then
            continue
        end
        local midX = center.Position.X
        local leftSlide = partsIn(ramp:FindFirstChild("LeftSlide"))
        local rightSlide = partsIn(ramp:FindFirstChild("RightSlide"))
        local spawns = partsIn(ramp:FindFirstChild("Spawnparts"))
        if #spawns == 0 and ramp ~= primaryRamp and primaryRamp then
            leftSlide = partsIn(primaryRamp:FindFirstChild("LeftSlide"))
            rightSlide = partsIn(primaryRamp:FindFirstChild("RightSlide"))
            spawns = partsIn(primaryRamp:FindFirstChild("Spawnparts"))
            local c2 = primaryRamp:FindFirstChild("Center")
            if c2 and c2:IsA("BasePart") then
                center = c2
                midX = center.Position.X
            end
        end
        paths[i] = buildPathForSlot(place, spawns, leftSlide, rightSlide, center, midX)
    end
    return paths
end

local _warnedMissing: { [string]: boolean } = {}

local function getPath(ownerUserId: number, slotIndex: number): { Vector3 }?
    local bucket = _pathsByOwner[ownerUserId]
    local path = if bucket then bucket[slotIndex] else nil
    if path and #path >= 2 then
        return path
    end
    -- Rebuild when missing / stale (ownership or plot streaming).
    bucket = buildPathsForOwner(ownerUserId)
    _pathsByOwner[ownerUserId] = bucket
    path = bucket[slotIndex]
    if path and #path >= 2 then
        return path
    end
    return nil
end

local function faceFlat(fromPos: Vector3, toPos: Vector3): CFrame
    local face = Vector3.new(toPos.X - fromPos.X, 0, toPos.Z - fromPos.Z)
    if face.Magnitude < 1e-3 then
        return CFrame.new()
    end
    return CFrame.lookAt(Vector3.zero, face.Unit)
end

function ConveyorVisual.spawn(
    slotIndex: number,
    heroId: string,
    travelSec: number,
    ownerUserId: number?,
    forLocalPlayer: boolean?
)
    local uid = ownerUserId or 0
    local path = getPath(uid, slotIndex)
    if not path or #path < 2 then
        local key = `{uid}:{slotIndex}`
        if not _warnedMissing[key] then
            _warnedMissing[key] = true
            warn(`[ConveyorVisual] no path for owner={uid} slot={slotIndex}`)
        end
        return
    end
    local mini = HeroModel.clone(heroId, nil, {
        targetHeight = HeroScaleLogic.MINI_HEIGHT,
        maxExtent = HeroScaleLogic.MINI_MAX_EXTENT,
    })
    if not mini then
        warn("[ConveyorVisual] failed to clone hero mini:", heroId)
        return
    end
    mini.Name = "Mini"
    mini.Parent = ensureFolder()

    local start = path[1]
    mini:PivotTo(CFrame.new(start) * faceFlat(path[1], path[2]))

    local segmentTime = travelSec / math.max(1, #path - 1)
    local creditLocal = forLocalPlayer == true
    task.spawn(function()
        for i = 2, #path do
            if not mini.Parent then
                return
            end
            local fromPos = mini:GetPivot().Position
            local toPos = path[i]
            local faceRot = faceFlat(fromPos, toPos)
            local fromCf = CFrame.new(fromPos) * faceRot
            local toCf = CFrame.new(toPos) * faceRot
            local t0 = os.clock()
            while os.clock() - t0 < segmentTime do
                if not mini.Parent then
                    return
                end
                local alpha = math.clamp((os.clock() - t0) / segmentTime, 0, 1)
                mini:PivotTo(fromCf:Lerp(toCf, alpha))
                task.wait()
            end
            mini:PivotTo(toCf)
        end
        if mini.Parent then
            mini:Destroy()
            if creditLocal then
                SellBoxVisual.deposit(1)
            end
        end
    end)
end

function ConveyorVisual.invalidatePaths()
    table.clear(_pathsByOwner)
end

function ConveyorVisual.start()
    table.clear(_pathsByOwner)
    ensureFolder()
    SellBoxVisual.start()
end

return ConveyorVisual
