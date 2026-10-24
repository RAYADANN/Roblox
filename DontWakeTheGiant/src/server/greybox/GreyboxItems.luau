--!strict
-- Предмет-кубик цвета редкости (этап 1). Контракт: Model с PrimaryPart "Root" в центре основания.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage.shared.data.ItemsConfig)
local Rarity = require(ReplicatedStorage.shared.data.Rarity)

local GreyboxItems = {}

function GreyboxItems.make(def: ItemsConfig.ItemDef): Model
    local model = Instance.new("Model")
    model.Name = def.id

    local size = ItemsConfig.GREYBOX_SIZE[math.clamp(def.weight, 1, #ItemsConfig.GREYBOX_SIZE)]
    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.CanQuery = false
    root.Anchored = true
    root.CFrame = CFrame.new()
    root.Parent = model

    local cube = Instance.new("Part")
    cube.Name = "Cube"
    cube.Size = Vector3.new(size, size, size)
    cube.CFrame = CFrame.new(0, size / 2, 0)
    cube.Color = (Rarity.DEFS :: any)[def.rarity].color
    cube.Material = if def.rarity == "Secret"
        then Enum.Material.Neon
        else Enum.Material.SmoothPlastic
    cube.CanCollide = false
    cube.Anchored = false
    cube.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = cube
    weld.Parent = cube

    model.PrimaryPart = root
    return model
end

return GreyboxItems
