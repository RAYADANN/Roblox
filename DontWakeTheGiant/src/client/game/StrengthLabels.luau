--!strict
-- Сила на виду (GDD 5.3, 9.1): над предметом «Need 2K 💪» (красным, если не поднять),
-- над каждым игроком «💪 100».

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatNumber = require(ReplicatedStorage.shared.util.FormatNumber)

local LABEL_DISTANCE = 70
local CAN_COLOR = Color3.fromHex("#4CD964")
local CANNOT_COLOR = Color3.fromHex("#FF5A4E")

local player = Players.LocalPlayer

local StrengthLabels = {}

local function myStrength(): number
    local value = player:GetAttribute("Strength")
    return if typeof(value) == "number" then value else 0
end

local function makeLabel(
    name: string,
    adornee: BasePart,
    offsetY: number,
    size: UDim2,
    maxDistance: number
): TextLabel
    local gui = Instance.new("BillboardGui")
    gui.Name = name
    gui.Size = size
    gui.StudsOffset = Vector3.new(0, offsetY, 0)
    gui.MaxDistance = maxDistance
    gui.AlwaysOnTop = false
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.FredokaOne
    label.TextScaled = true
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.Parent = gui
    gui.Parent = adornee
    return label
end

local itemLabels: { [Model]: TextLabel } = {}

local function refreshItem(item: Model, label: TextLabel)
    local need = item:GetAttribute("Need")
    if typeof(need) ~= "number" then
        return
    end
    local can = myStrength() >= need
    label.Text = `Need {FormatNumber.short(need)} 💪`
    label.TextColor3 = if can then CAN_COLOR else CANNOT_COLOR
end

local function trackItem(item: Instance)
    if not item:IsA("Model") or itemLabels[item] then
        return
    end
    -- Дети модели могут прийти позже самой модели (репликация, StreamingEnabled).
    local root = item.PrimaryPart or item:WaitForChild("Root", 10)
    if not root or not root:IsA("BasePart") or itemLabels[item] then
        return
    end
    local _, size = item:GetBoundingBox()
    local label =
        makeLabel("NeedLabel", root, size.Y + 1.5, UDim2.fromOffset(120, 28), LABEL_DISTANCE)
    itemLabels[item] = label
    refreshItem(item, label)
    item.AncestryChanged:Connect(function()
        -- Несомый предмет переезжает в персонажа: табличка над головой несущего не нужна.
        label.Parent.Enabled = item.Parent ~= nil and item.Parent.Name == "Items"
        if not item.Parent then
            itemLabels[item] = nil
        end
    end)
end

local function trackCharacter(other: Player, character: Model)
    local head = character:WaitForChild("Head", 10)
    if not head or not head:IsA("BasePart") then
        return
    end
    local label = makeLabel("StrengthLabel", head, 3, UDim2.fromOffset(110, 26), 90)
    local function update()
        local value = other:GetAttribute("Strength")
        label.Text = `💪 {FormatNumber.short(if typeof(value) == "number" then value else 0)}`
    end
    update()
    other:GetAttributeChangedSignal("Strength"):Connect(update)
end

local function trackPlayer(other: Player)
    other.CharacterAdded:Connect(function(character)
        trackCharacter(other, character)
    end)
    if other.Character then
        task.spawn(trackCharacter, other, other.Character)
    end
end

function StrengthLabels.start()
    local items = workspace:WaitForChild("Items")
    for _, item in items:GetChildren() do
        task.spawn(trackItem, item)
    end
    items.ChildAdded:Connect(function(item)
        task.spawn(trackItem, item)
    end)
    player:GetAttributeChangedSignal("Strength"):Connect(function()
        for item, label in itemLabels do
            refreshItem(item, label)
        end
    end)
    Players.PlayerAdded:Connect(trackPlayer)
    for _, other in Players:GetPlayers() do
        trackPlayer(other)
    end
end

return StrengthLabels
