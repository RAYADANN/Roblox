--!strict
-- Graybox aim_map: flat floor + two spawns if Studio has no map yet.

local CrosshairWall = require(script.Parent.CrosshairWall)

local ArenaBootstrap = {}

local ARENA_NAME = "AimArena"

export type ArenaSpawns = {
    spawnA: CFrame,
    spawnB: CFrame,
}

local function part(props: {
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    anchored: boolean?,
    parent: Instance,
}): BasePart
    local p = Instance.new("Part")
    p.Name = props.name
    p.Size = props.size
    p.CFrame = props.cframe
    p.Color = props.color
    p.Anchored = if props.anchored == nil then true else props.anchored
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = props.parent
    return p
end

function ArenaBootstrap.ensure(): ArenaSpawns
    local existing = workspace:FindFirstChild(ARENA_NAME)
    local folder: Instance
    if existing then
        folder = existing
        local a = existing:FindFirstChild("SpawnA")
        local b = existing:FindFirstChild("SpawnB")
        if a and a:IsA("BasePart") and b and b:IsA("BasePart") then
            CrosshairWall.ensure(folder)
            local posA = a.Position + Vector3.new(0, 3, 0)
            local posB = b.Position + Vector3.new(0, 3, 0)
            return {
                spawnA = CFrame.lookAt(posA, posB),
                spawnB = CFrame.lookAt(posB, posA),
            }
        end
    end

    folder = Instance.new("Folder")
    folder.Name = ARENA_NAME
    folder.Parent = workspace

    part({
        name = "Floor",
        size = Vector3.new(120, 1, 40),
        cframe = CFrame.new(0, 0, 0),
        color = Color3.fromRGB(70, 74, 82),
        parent = folder,
    })

    -- Side walls (long aim lane)
    part({
        name = "WallLeft",
        size = Vector3.new(1, 12, 40),
        cframe = CFrame.new(-60, 6, 0),
        color = Color3.fromRGB(55, 58, 64),
        parent = folder,
    })
    part({
        name = "WallRight",
        size = Vector3.new(1, 12, 40),
        cframe = CFrame.new(60, 6, 0),
        color = Color3.fromRGB(55, 58, 64),
        parent = folder,
    })

    local spawnA = part({
        name = "SpawnA",
        size = Vector3.new(6, 1, 6),
        cframe = CFrame.new(-48, 1, 0),
        color = Color3.fromRGB(80, 140, 255),
        parent = folder,
    })
    local spawnB = part({
        name = "SpawnB",
        size = Vector3.new(6, 1, 6),
        cframe = CFrame.new(48, 1, 0),
        color = Color3.fromRGB(255, 100, 90),
        parent = folder,
    })

    CrosshairWall.ensure(folder)

    local posA = spawnA.Position + Vector3.new(0, 3, 0)
    local posB = spawnB.Position + Vector3.new(0, 3, 0)
    return {
        spawnA = CFrame.lookAt(posA, posB),
        spawnB = CFrame.lookAt(posB, posA),
    }
end

return ArenaBootstrap
