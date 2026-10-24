--!strict
-- Помощники сборки серых заглушек. Только рантайм, в Workspace.Greybox.

local Build = {}

Build.COLORS = {
    grass = Color3.fromHex("#4B974B"),
    darkGrass = Color3.fromHex("#27462D"),
    dirt = Color3.fromHex("#7C5C46"),
    stone = Color3.fromHex("#A3A2A5"),
    darkStone = Color3.fromHex("#636067"),
    gold = Color3.fromHex("#F5CD30"),
    darkGold = Color3.fromHex("#C7A21D"),
    moss = Color3.fromHex("#6B8E3A"),
    water = Color3.fromHex("#3D8FD6"),
    wood = Color3.fromHex("#A0662E"),
    white = Color3.fromHex("#F2F3F3"),
    red = Color3.fromHex("#C4281C"),
    blue = Color3.fromHex("#0D69AC"),
    skin = Color3.fromHex("#F2C094"),
    overalls = Color3.fromHex("#3D6BA8"),
    beard = Color3.fromHex("#B5532A"),
    leather = Color3.fromHex("#7C5C46"),
}

export type PartProps = {
    name: string?,
    size: Vector3,
    cframe: CFrame,
    color: Color3?,
    class: string?,
    transparency: number?,
    canCollide: boolean?,
    canQuery: boolean?,
    material: Enum.Material?,
    shape: Enum.PartType?,
    attributes: { [string]: any }?,
    parent: Instance,
}

function Build.part(p: PartProps): BasePart
    local part = Instance.new((p.class or "Part") :: any) :: BasePart
    part.Name = p.name or "Part"
    part.Anchored = true
    part.Size = p.size
    part.CFrame = p.cframe
    part.Color = p.color or Build.COLORS.stone
    part.Material = p.material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Transparency = p.transparency or 0
    part.CanCollide = if p.canCollide == nil then true else p.canCollide
    part.CanQuery = if p.canQuery == nil then true else p.canQuery
    if p.shape and part:IsA("Part") then
        part.Shape = p.shape
    end
    if p.attributes then
        for key, value in p.attributes do
            part:SetAttribute(key, value)
        end
    end
    part.Parent = p.parent
    return part
end

-- Блок по нижней грани: base — центр основания.
function Build.block(
    parent: Instance,
    name: string,
    size: Vector3,
    base: Vector3,
    color: Color3,
    attributes: { [string]: any }?
): BasePart
    return Build.part({
        name = name,
        size = size,
        cframe = CFrame.new(base + Vector3.new(0, size.Y / 2, 0)),
        color = color,
        attributes = attributes,
        parent = parent,
    })
end

-- Горизонтальный диск-цилиндр с верхом на topY.
function Build.disc(
    parent: Instance,
    name: string,
    radius: number,
    topY: number,
    height: number,
    color: Color3,
    attributes: { [string]: any }?
): BasePart
    return Build.part({
        name = name,
        size = Vector3.new(height, radius * 2, radius * 2),
        cframe = CFrame.new(0, topY - height / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
        color = color,
        shape = Enum.PartType.Cylinder,
        attributes = attributes,
        parent = parent,
    })
end

-- Кольцо из сегментов по 15° (сетка stud-стиля). skip(angleDeg) пропускает сегмент.
function Build.ring(
    parent: Instance,
    name: string,
    rInner: number,
    rOuter: number,
    bottomY: number,
    topY: number,
    color: Color3,
    opts: {
        segments: number?,
        skip: ((number) -> boolean)?,
        transparency: number?,
        attributes: { [string]: any }?,
    }?
)
    local o = opts or {}
    local segments = o.segments or 24
    local step = 360 / segments
    local depth = rOuter - rInner
    local width = 2 * rOuter * math.sin(math.rad(step / 2)) + 1
    local mid = (rInner + rOuter) / 2
    for i = 0, segments - 1 do
        local angle = i * step
        if o.skip and o.skip(angle) then
            continue
        end
        local a = math.rad(angle)
        local pos = Vector3.new(math.cos(a) * mid, (bottomY + topY) / 2, math.sin(a) * mid)
        local outward = Vector3.new(math.cos(a), 0, math.sin(a))
        Build.part({
            name = name,
            size = Vector3.new(width, topY - bottomY, depth),
            cframe = CFrame.lookAt(pos, pos + outward),
            color = color,
            transparency = o.transparency,
            attributes = o.attributes,
            parent = parent,
        })
    end
end

function Build.polar(radius: number, angleDeg: number, y: number): Vector3
    local a = math.rad(angleDeg)
    return Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
end

function Build.folder(parent: Instance, name: string): Folder
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

-- Маркер точки появления (GDD 2.5): невидимый, тег HoardSpawn, атрибут Ring.
function Build.spawnMarker(parent: Instance, ring: string, position: Vector3): BasePart
    local marker = Build.part({
        name = `HoardSpawn_{ring}`,
        size = Vector3.new(2, 0.4, 2),
        cframe = CFrame.new(position + Vector3.new(0, 0.2, 0)),
        transparency = 1,
        canCollide = false,
        canQuery = false,
        attributes = { Ring = ring },
        parent = parent,
    })
    marker:AddTag("HoardSpawn")
    return marker
end

return Build
