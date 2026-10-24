--!strict
-- Серые участки (GDD 6.1): 8 штук 40×40 на радиусе 200, вход смотрит на великана.
-- Контракт: Plot<i> { Floor, Spawn, Pedestals/P1..P6, LockButton, Barrier/*, Sign }.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require(script.Parent.Build)
local GameplayConfig = require(ReplicatedStorage.shared.data.GameplayConfig)

local C = Build.COLORS
local V = Vector3.new

local GreyboxPlots = {}

local function buildPlot(parent: Instance, index: number): Model
    local plot = Instance.new("Model")
    plot.Name = `Plot{index}`
    plot:SetAttribute("Index", index)

    local half = GameplayConfig.PLOT_SIZE / 2
    local angle = (index - 1) * 360 / GameplayConfig.PLOT_COUNT
    local center = Build.polar(GameplayConfig.PLOT_RADIUS, angle, GameplayConfig.PLOT_Y)
    -- LookVector (−Z) направлен на великана: вход спереди.
    local cf = CFrame.lookAt(center, V(0, GameplayConfig.PLOT_Y, 0))
    local color = GameplayConfig.PLOT_COLORS[index]

    local function at(
        name: string,
        size: Vector3,
        offset: Vector3,
        partColor: Color3,
        extra: { [string]: any }?
    ): BasePart
        local props: Build.PartProps = {
            name = name,
            size = size,
            cframe = cf * CFrame.new(offset),
            color = partColor,
            parent = plot,
        }
        if extra then
            for key, value in extra do
                (props :: any)[key] = value
            end
        end
        return Build.part(props)
    end

    local floor = at(
        "Floor",
        V(GameplayConfig.PLOT_SIZE, 0.4, GameplayConfig.PLOT_SIZE),
        V(0, 0.2, 0),
        C.grass
    )
    plot.PrimaryPart = floor

    -- Заборчик в цвете игрока, разрыв 10 stud на входе.
    at("FenceBack", V(40, 1.2, 1), V(0, 1, half - 0.5), color)
    at("FenceL", V(1, 1.2, 40), V(-half + 0.5, 1, 0), color)
    at("FenceR", V(1, 1.2, 40), V(half - 0.5, 1, 0), color)
    at("FenceFrontL", V(15, 1.2, 1), V(-12.5, 1, -half + 0.5), color)
    at("FenceFrontR", V(15, 1.2, 1), V(12.5, 1, -half + 0.5), color)

    at("Spawn", V(6, 0.2, 6), V(0, 0.5, 14), C.white, { transparency = 0.5, canCollide = false })

    -- 6 открытых пьедесталов в ряд, шаг 4.5. Два кирпича 4×1.2×4.
    local pedestals = Instance.new("Folder")
    pedestals.Name = "Pedestals"
    pedestals.Parent = plot
    local open = GameplayConfig.PEDESTALS_OPEN
    for i = 1, open do
        local x = (i - (open + 1) / 2) * GameplayConfig.PEDESTAL_STEP
        local pedestal = Build.part({
            name = `P{i}`,
            size = V(4, 2.4, 4),
            cframe = cf * CFrame.new(x, 1.6, 4),
            color = C.stone,
            parent = pedestals,
        })
        pedestal:SetAttribute("Slot", i)
    end

    -- Кнопка замка у входа.
    at("LockBase", V(3, 3, 3), V(9, 1.9, -half + 3), C.darkStone)
    at("LockButton", V(2, 0.6, 2), V(9, 3.7, -half + 3), C.red)

    -- Вывеска: имя и доход.
    at("SignPostL", V(1, 8, 1), V(-6, 4.4, -half + 0.5), C.wood)
    at("SignPostR", V(1, 8, 1), V(6, 4.4, -half + 0.5), C.wood)
    at("Sign", V(13, 3, 0.6), V(0, 9, -half + 0.5), C.wood)

    -- Барьер замка: стены ForceField. Сервер не сталкивает, сталкивает клиент чужих участков.
    local barrier = Instance.new("Folder")
    barrier.Name = "Barrier"
    barrier.Parent = plot
    local function wall(name: string, size: Vector3, offset: Vector3)
        Build.part({
            name = name,
            size = size,
            cframe = cf * CFrame.new(offset),
            color = color,
            material = Enum.Material.ForceField,
            transparency = 1,
            canCollide = false,
            canQuery = false,
            parent = barrier,
        })
    end
    wall("Front", V(40, 14, 1), V(0, 7.4, -half - 0.5))
    wall("Back", V(40, 14, 1), V(0, 7.4, half + 0.5))
    wall("Left", V(1, 14, 40), V(-half - 0.5, 7.4, 0))
    wall("Right", V(1, 14, 40), V(half + 0.5, 7.4, 0))

    plot.Parent = parent
    return plot
end

function GreyboxPlots.build(root: Folder): Folder
    local plots = Build.folder(root, "Plots")
    for i = 1, GameplayConfig.PLOT_COUNT do
        buildPlot(plots, i)
    end
    return plots
end

return GreyboxPlots
