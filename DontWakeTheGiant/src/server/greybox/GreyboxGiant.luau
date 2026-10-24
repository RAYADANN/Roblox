--!strict
-- Серый великан Grumble (GDD 4.1): лежит на спине вдоль X, голова на западе.
-- Каждая подмодель: PrimaryPart "Joint" в суставе. Строится, только если нет Workspace.Giant.

local Build = require(script.Parent.Build)

local C = Build.COLORS
local V = Vector3.new

local GreyboxGiant = {}

local BODY = { Surface = "Body" }

local function sub(giant: Model, name: string, joint: Vector3): Model
    local model = Instance.new("Model")
    model.Name = name
    local jointPart = Build.part({
        name = "Joint",
        size = V(1, 1, 1),
        cframe = CFrame.new(joint),
        transparency = 1,
        canCollide = false,
        canQuery = false,
        parent = model,
    })
    model.PrimaryPart = jointPart
    model.Parent = giant
    return model
end

local function box(
    parent: Instance,
    name: string,
    size: Vector3,
    center: Vector3,
    color: Color3,
    attributes: { [string]: any }?
): BasePart
    return Build.part({
        name = name,
        size = size,
        cframe = CFrame.new(center),
        color = color,
        attributes = attributes,
        parent = parent,
    })
end

function GreyboxGiant.build(root: Instance): Model
    local giant = Instance.new("Model")
    giant.Name = "Giant"

    -- Торс 40×20×34 (лежит): X −40..0, Y 6..26. Pivot — бёдра.
    local torso = sub(giant, "Torso", V(0, 16, 0))
    box(torso, "Body", V(40, 20, 34), V(-20, 16, 0), C.overalls, BODY)
    box(torso, "Patch", V(8, 0.4, 8), V(-16, 26.2, 9), C.red, BODY)
    Build.spawnMarker(torso, "Inner", V(-36, 26, 12)) -- нагрудный карман

    -- Борода-лестница на живот: ступени по 3.5 stud с южной стороны.
    local beard = sub(giant, "Beard", V(-22, 6, 17))
    for k = 1, 6 do
        local top = 6 + 3.5 * k
        local z = 17 + (6 - k) * 4 + 2
        box(
            beard,
            `BeardStep{k}`,
            V(8, top - 6, 4),
            V(-22, (6 + top) / 2, z),
            if k % 2 == 0 then C.beard else Color3.fromHex("#D9733A"),
            BODY
        )
    end

    -- Живот: отдельная «дышащая» платформа.
    local belly = sub(giant, "Belly", V(-20, 26.5, 3))
    box(belly, "Platform", V(30, 1, 20), V(-20, 26.5, 3), C.white, BODY)
    Build.spawnMarker(belly, "Inner", V(-12, 27, 8))
    Build.spawnMarker(belly, "Inner", V(-28, 27, 9))
    Build.spawnMarker(belly, "Teddy", V(-22, 27, -4))

    -- Голова 20×20×22, pivot — шея.
    local head = sub(giant, "Head", V(-40, 16, 0))
    box(head, "Skull", V(20, 20, 22), V(-50, 16, 0), C.skin, BODY)
    box(head, "Nose", V(5, 5, 6), V(-46, 28.5, 0), Color3.fromHex("#E8A07A"), BODY)
    box(head, "BrowL", V(3, 2, 8), V(-55, 27, -5), C.beard, BODY)
    box(head, "BrowR", V(3, 2, 8), V(-55, 27, 5), C.beard, BODY)
    box(head, "EyeL", V(3, 1, 5), V(-52, 26.5, -5), C.white)
    box(head, "EyeR", V(3, 1, 5), V(-52, 26.5, 5), C.white)
    box(head, "NightcapA", V(8, 14, 16), V(-64, 14, 0), C.blue, BODY)
    box(head, "NightcapB", V(6, 10, 12), V(-71, 12, 0), C.white, BODY)
    Build.part({
        name = "Pompom",
        size = V(6, 6, 6),
        cframe = CFrame.new(-77, 10, 0),
        color = C.white,
        shape = Enum.PartType.Ball,
        attributes = BODY,
        parent = head,
    })

    -- Веки: отдельная подмодель, поднимаются в Eye Open.
    local lids = sub(giant, "Lids", V(-40, 16, 0))
    box(lids, "LidL", V(3.4, 1, 5.4), V(-52, 27.2, -5), C.skin)
    box(lids, "LidR", V(3.4, 1, 5.4), V(-52, 27.2, 5), C.skin)

    -- Левая рука обнимает мишку на груди.
    local armL = sub(giant, "ArmL", V(-34, 26, -12))
    box(armL, "Arm", V(30, 10, 10), V(-22, 31, -12), C.white, BODY)

    -- Правая рука откинута на юг ладонью вверх. Ладонь — хитбокс взмаха и точка Hand.
    local armR = sub(giant, "ArmR", V(-34, 8, 17))
    box(armR, "Arm", V(12, 10, 36), V(-34, 8, 35), C.white, BODY)
    box(armR, "Hand", V(14, 4, 14), V(-34, 2.5, 60), C.skin, BODY)
    Build.spawnMarker(armR, "Hand", V(-34, 4.5, 60))

    -- Ноги 14×14×44.
    local legL = sub(giant, "LegL", V(0, 13, -9))
    box(legL, "Leg", V(44, 14, 14), V(22, 13, -9), C.overalls, BODY)
    box(legL, "Boot", V(12, 18, 16), V(50, 11, -9), C.leather, BODY)
    local legR = sub(giant, "LegR", V(0, 13, 9))
    box(legR, "Leg", V(44, 14, 14), V(22, 13, 9), C.overalls, BODY)
    box(legR, "Sock", V(10, 16, 14), V(49, 12, 9), C.red, BODY)

    -- Конус взгляда рисует клиент; подмодель — для контракта.
    sub(giant, "Gaze", V(-52, 27, -5))

    -- Точки Inner рядом с великаном, на горе сокровищ.
    local nearby = Instance.new("Folder")
    nearby.Name = "InnerSpawns"
    nearby.Parent = giant
    for _, xz in { { -10, -30 }, { 15, 28 }, { 30, -26 }, { -38, -26 }, { -30, -36 } } do
        -- Высота ступени горы (радиусы 18/26/34/42/50 → верх 6.0 … 1.2).
        local r = math.sqrt(xz[1] ^ 2 + xz[2] ^ 2)
        local step = math.clamp(5 - math.floor((r - 18) / 8 + 1), 0, 5)
        Build.spawnMarker(nearby, "Inner", V(xz[1], step * 1.2, xz[2]))
    end

    giant.PrimaryPart = torso.PrimaryPart
    giant.Parent = root
    return giant
end

return GreyboxGiant
