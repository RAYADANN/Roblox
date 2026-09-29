--!strict
-- Minis: SpawnPartN → LeftSlideN/RightSlideN (one segment) → Center → exit.

local Workspace = game:GetService("Workspace")

local HeroModel = require(script.Parent.HeroModel)
local RampWorldRenderer = require(script.Parent.RampWorldRenderer)

local ConveyorVisual = {}

local Y_OFF = 1.15
local MID_X = 64 -- left pads/spawns < mid, right >

local _folder: Folder? = nil
local _paths: { [number]: { Vector3 } } = {}

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

local function lift(pos: Vector3): Vector3
    return pos + Vector3.new(0, Y_OFF, 0)
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

--[[
  Path per slot (one row only):
  SpawnPartN → LeftSlideN / RightSlideN → join Center at that Z → exit along Center
  Example: SpawnPart1 → LeftSlide1 → Center → exit
]]
local function buildPathForSlot(
    place: BasePart,
    spawns: { BasePart },
    leftSlide: { BasePart },
    rightSlide: { BasePart },
    center: BasePart
): { Vector3 }
    local sameLeft = place.Position.X < MID_X
    local lane = if sameLeft then leftSlide else rightSlide

    local leftSpawns: { BasePart } = {}
    local rightSpawns: { BasePart } = {}
    for _, s in spawns do
        if s.Position.X < MID_X then
            table.insert(leftSpawns, s)
        else
            table.insert(rightSpawns, s)
        end
    end
    local spawnPool = if sameLeft then leftSpawns else rightSpawns
    local spawn = nearestByZ(spawnPool, place.Position.Z)
    if not spawn then
        return { lift(place.Position) }
    end

    local slide = nearestByZ(lane, spawn.Position.Z)
    local path: { Vector3 } = { lift(spawn.Position) }
    if slide then
        table.insert(path, lift(slide.Position))
    end

    -- Turn onto Center at this row's Z, then ride Center the other way to exit.
    local rowZ = if slide then slide.Position.Z else spawn.Position.Z
    table.insert(path, lift(Vector3.new(center.Position.X, center.Position.Y, rowZ)))

    local halfZ = center.Size.Z * 0.5
    -- Opposite of Center.LookVector (was going the wrong way along Center).
    local exitPos = center.Position - center.CFrame.LookVector * halfZ
    table.insert(path, lift(exitPos))
    return path
end

local function buildPaths()
    table.clear(_paths)
    local ramp = Workspace:FindFirstChild("Ramp")
    if not ramp then
        return
    end
    local center = ramp:FindFirstChild("Center")
    if not center or not center:IsA("BasePart") then
        warn("[ConveyorVisual] Ramp.Center missing")
        return
    end

    local leftSlide = partsIn(ramp:FindFirstChild("LeftSlide"))
    local rightSlide = partsIn(ramp:FindFirstChild("RightSlide"))
    local spawns = partsIn(ramp:FindFirstChild("Spawnparts"))

    for i = 1, 10 do
        local place = RampWorldRenderer.getPlacePart(i)
        if place then
            _paths[i] = buildPathForSlot(place, spawns, leftSlide, rightSlide, center)
        end
    end
end

local function faceFlat(fromPos: Vector3, toPos: Vector3): CFrame
    local face = Vector3.new(toPos.X - fromPos.X, 0, toPos.Z - fromPos.Z)
    if face.Magnitude < 1e-3 then
        return CFrame.new()
    end
    return CFrame.lookAt(Vector3.zero, face.Unit)
end

function ConveyorVisual.spawn(slotIndex: number, heroId: string, travelSec: number)
    if next(_paths) == nil then
        buildPaths()
    end
    local path = _paths[slotIndex]
    if not path or #path < 2 then
        warn(`[ConveyorVisual] no path for slot {slotIndex}`)
        return
    end
    local mini = HeroModel.clone(heroId, 0.35)
    if not mini then
        warn("[ConveyorVisual] failed to clone Secret mini")
        return
    end
    mini.Name = "Mini"
    mini.Parent = ensureFolder()

    local start = path[1]
    mini:PivotTo(CFrame.new(start) * faceFlat(path[1], path[2]))

    local segmentTime = travelSec / math.max(1, #path - 1)
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
        end
    end)
end

function ConveyorVisual.start()
    buildPaths()
    ensureFolder()
end

return ConveyorVisual
