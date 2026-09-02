--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local CloseButton = require(script.Parent.Parent.components.CloseButton)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local shines: { theme.Shine } = { "linear", "radial", "diamond" }

local children: { [string]: React.Node } = {
    Pad = React.createElement("UIPadding", {
        PaddingTop = UDim.new(0, 24),
        PaddingLeft = UDim.new(0, 24),
    }),
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 16),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
}

for i, shine in shines do
    children[shine] = React.createElement(CloseButton, {
        shine = shine,
        size = UDim2.fromOffset(56, 56),
        layoutOrder = i,
    })
end

return mount(React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg,
    BorderSizePixel = 0,
}, children))
