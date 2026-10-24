--!strict
-- Серая карта «Snoring Hollow» по GDD 3.2–3.3. Строится, только если нет Workspace.Level.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local GameplayConfig = require(ReplicatedStorage.shared.data.GameplayConfig)
local GiantConfig = require(ReplicatedStorage.shared.data.GiantConfig)

local C = Build.COLORS
local V = Vector3.new

local GreyboxMap = {}

local function isRampAngle(angle: number): boolean
    return angle % (360 / GameplayConfig.PLOT_COUNT) == 0
end

local function buildValley(map: Folder)
    Build.block(map, "Floor", V(520, 2, 520), V(0, -2, 0), C.grass)
    -- Террасы 140–175: 3 ступени по 6 stud. В местах пандусов вырезаны.
    local terraces = Build.folder(map, "Terraces")
    Build.ring(terraces, "Terrace1", 140, 152, 0, 6, C.darkGrass, { skip = isRampAngle })
    Build.ring(terraces, "Terrace2", 152, 164, 0, 12, C.grass, { skip = isRampAngle })
    Build.ring(terraces, "Terrace3", 164, 175, 0, 18, C.darkGrass, { skip = isRampAngle })
    Build.ring(map, "Plateau", 175, 235, 0, GameplayConfig.PLOT_Y, C.grass)
    Build.ring(map, "MountainWall", 235, 255, 0, 80, C.darkStone)
    Build.ring(map, "InvisibleWall", 250, 256, 80, 300, C.white, { transparency = 1 })

    -- 8 пандусов шириной 8 от участков вниз.
    local ramps = Build.folder(map, "Ramps")
    for i = 0, GameplayConfig.PLOT_COUNT - 1 do
        local angle = i * 360 / GameplayConfig.PLOT_COUNT
        local a = math.rad(angle)
        local outward = V(math.cos(a), 0, math.sin(a))
        local pos = outward * 157.5 + V(0, GameplayConfig.PLOT_Y / 2, 0)
        Build.part({
            name = "Ramp",
            class = "WedgePart",
            size = V(8, GameplayConfig.PLOT_Y, 35),
            cframe = CFrame.lookAt(pos, pos + outward),
            color = C.dirt,
            parent = ramps,
        })
        -- Флажок «Shh!» у границы зоны.
        Build.block(ramps, "ShhFlag", V(1, 6, 1), outward * 143 + V(5, 6, 0), C.white)
    end

    -- Граница зоны шума: кольцо мелких золотых монет.
    Build.ring(
        map,
        "ZoneBorder",
        GiantConfig.ZONE_RADIUS - 1,
        GiantConfig.ZONE_RADIUS + 1,
        0,
        0.2,
        C.gold,
        {
            segments = 48,
        }
    )
end

local function buildHoardMountain(map: Folder)
    -- Гора сокровищ: Y 0–6 ступенями по 1.2.
    local mountain = Build.folder(map, "TreasureMountain")
    local radii = { 50, 42, 34, 26, 18 }
    for i, radius in radii do
        Build.disc(
            mountain,
            `Step{i}`,
            radius,
            i * 1.2,
            1.2,
            if i % 2 == 0 then C.gold else C.darkGold
        )
    end
end

local function buildRoutes(map: Folder)
    local routes = Build.folder(map, "Routes")
    -- Мшистые дорожки (Quiet): зигзаг от каждого пандуса к среднему кольцу, длиннее прямой.
    for i = 0, GameplayConfig.PLOT_COUNT - 1 do
        local angle = i * 360 / GameplayConfig.PLOT_COUNT
        local points = {
            Build.polar(140, angle, 0),
            Build.polar(122, angle + 9, 0),
            Build.polar(104, angle - 7, 0),
            Build.polar(88, angle + 6, 0),
            Build.polar(60, angle + 2, 0),
        }
        for k = 1, #points - 1 do
            local from, to = points[k], points[k + 1]
            local len = (to - from).Magnitude
            local mid = (from + to) / 2 + V(0, 0.2, 0)
            Build.part({
                name = "MossPath",
                size = V(5, 0.4, len + 4),
                cframe = CFrame.lookAt(mid, to + V(0, 0.2, 0)),
                color = C.moss,
                attributes = { Surface = "Quiet" },
                parent = routes,
            })
        end
    end
    -- Груды монет (Crunchy): кратчайший путь к центру по осям.
    for i = 0, 3 do
        local angle = 22.5 + i * 90
        local mid = Build.polar(95, angle, 0.3)
        Build.part({
            name = "CoinPile",
            size = V(10, 0.6, 90),
            cframe = CFrame.lookAt(mid, V(0, 0.3, 0)),
            color = C.gold,
            attributes = { Surface = "Crunchy" },
            parent = routes,
        })
    end
    for i = 0, 3 do
        local center = Build.polar(70, 75 + i * 90, 0)
        Build.block(routes, "CoinHeap", V(16, 1.2, 16), center, C.gold, { Surface = "Crunchy" })
        Build.block(
            routes,
            "CoinHeap",
            V(10, 1.2, 10),
            center + V(0, 1.2, 0),
            C.darkGold,
            { Surface = "Crunchy" }
        )
    end
end

local function buildCover(map: Folder)
    local cover = Build.folder(map, "Cover")
    local coverAttr = { Cover = true }

    -- Сапог великана: полый туннель 24×14×10, взгляд внутрь не достаёт.
    local bootBase = Build.polar(115, 45, 0)
    local bootCf = CFrame.lookAt(bootBase, bootBase + V(1, 0, -1))
    local function bootPart(name: string, size: Vector3, offset: Vector3)
        Build.part({
            name = name,
            size = size,
            cframe = bootCf * CFrame.new(offset),
            color = C.leather,
            attributes = coverAttr,
            parent = cover,
        })
    end
    bootPart("BootTop", V(14, 1, 24), V(0, 9.5, 0))
    bootPart("BootWallL", V(1, 9, 24), V(-6.5, 4.5, 0))
    bootPart("BootWallR", V(1, 9, 24), V(6.5, 4.5, 0))
    bootPart("BootToe", V(14, 10, 4), V(0, 5, 14))
    Build.block(cover, "Sock", V(6, 4, 6), (bootCf * CFrame.new(0, 0, -14)).Position, C.red)

    -- Опрокинутая кружка ø16, длина 18 + ручка-арка + молочная лужа.
    local mugPos = Build.polar(110, 135, 8)
    Build.part({
        name = "Mug",
        size = V(18, 16, 16),
        cframe = CFrame.new(mugPos),
        color = C.white,
        shape = Enum.PartType.Cylinder,
        attributes = coverAttr,
        parent = cover,
    })
    Build.block(cover, "MugHandleTop", V(4, 2, 10), mugPos + V(0, 8, 13), C.white, coverAttr)
    Build.block(cover, "MugHandleL", V(4, 10, 2), mugPos + V(0, -8, 9), C.white, coverAttr)
    Build.block(cover, "MugHandleR", V(4, 10, 2), mugPos + V(0, -8, 17), C.white, coverAttr)
    Build.block(
        cover,
        "MilkPuddle",
        V(20, 0.4, 14),
        mugPos + V(14, -8, 0),
        C.white,
        { Surface = "Milk" }
    )

    -- Стопка книг: три книги лесенкой, сверху видно полсокровищницы.
    local bookColors = { C.red, C.blue, C.grass }
    local bookBase = Build.polar(100, 200, 0)
    for i = 1, 3 do
        Build.block(
            cover,
            `Book{i}`,
            V(20, 4, 14),
            bookBase + V((i - 1) * 6, (i - 1) * 4, 0),
            bookColors[i],
            coverAttr
        )
    end

    -- 4 опрокинутых сундука в среднем кольце.
    for i = 0, 3 do
        local pos = Build.polar(70, i * 90, 0)
        Build.block(cover, "Chest", V(10, 6, 8), pos, C.wood, coverAttr)
    end
end

local function buildStream(map: Folder)
    -- Ручей пересекает южную половину внешнего кольца. Скорость ×0.6, шум ×2.
    local stream = Build.folder(map, "Stream")
    Build.part({
        name = "Water",
        size = V(170, 0.4, 10),
        cframe = CFrame.new(0, 0.2, 115),
        color = C.water,
        transparency = 0.2,
        attributes = { Surface = "Water" },
        parent = stream,
    })
    -- Ложка-мост: единственный сухой переход на юге, узкая.
    Build.block(stream, "SpoonBridge", V(4, 0.8, 40), V(20, 0, 115), C.stone)
    Build.block(stream, "SpoonBowl", V(10, 0.8, 8), V(20, 0, 139), C.stone)
end

function GreyboxMap.build(root: Folder): Folder
    local map = Build.folder(root, "Map")
    buildValley(map)
    buildHoardMountain(map)
    buildRoutes(map)
    buildCover(map)
    buildStream(map)
    return map
end

-- Точки Outer и Middle на земле (Inner/Hand/Teddy строит великан).
function GreyboxMap.buildSpawns(
    root: Folder,
    rings: {
        [string]: { count: number, minRadius: number, maxRadius: number },
    }
): Folder
    local spawns = Build.folder(root, "HoardSpawns")
    for _, ringName in { "Outer", "Middle" } do
        local ring = rings[ringName]
        for i = 0, ring.count - 1 do
            local angle = (i + 0.5) * 360 / ring.count
            -- Чередуем радиус, чтобы точки не стояли на одной окружности.
            local t = if i % 2 == 0 then 0.3 else 0.7
            local radius = ring.minRadius + 5 + (ring.maxRadius - ring.minRadius - 10) * t
            local pos = Build.polar(radius, angle, 0)
            if math.abs(pos.Z - 115) < 8 then
                pos = Build.polar(radius - 14, angle, 0)
            end
            Build.spawnMarker(spawns, ringName, pos)
        end
    end
    return spawns
end

return GreyboxMap
