--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Slot = require(script.Parent.Parent.components.Slot)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local rarities: { theme.SlotRarity } = { "purple", "gold", "blue", "orange", "green", "red" }

local children: { [string]: React.Node } = {
    Pad = React.createElement("UIPadding", {
        PaddingTop = UDim.new(theme.Space.pad, 0),
        PaddingLeft = UDim.new(theme.Space.pad, 0),
    }),
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(theme.Space.gap, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Wraps = true,
    }),
}

for i, rarity in rarities do
    children[rarity] = React.createElement(Slot, {
        rarity = rarity,
        size = UDim2.fromScale(0.12, 0.12),
        layoutOrder = i,
    })
end

return mount(React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg,
    BorderSizePixel = 0,
}, children))
