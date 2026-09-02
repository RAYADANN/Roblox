--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local OutlinedText = require(script.Parent.Parent.components.OutlinedText)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

return mount(React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg,
    BorderSizePixel = 0,
}, {
    Pad = React.createElement("UIPadding", {
        PaddingTop = UDim.new(theme.Space.pad, 0),
        PaddingLeft = UDim.new(theme.Space.pad, 0),
    }),
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(theme.Space.gap, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    Title = React.createElement(OutlinedText, {
        text = "INVENTORY",
        variant = "title",
        size = UDim2.fromScale(0, 0.07),
        layoutOrder = 1,
    }),
    Body = React.createElement(OutlinedText, {
        text = "DEFAULT TEXT",
        variant = "body",
        size = UDim2.fromScale(0, 0.045),
        layoutOrder = 2,
    }),
    Count = React.createElement(OutlinedText, {
        text = "1/415",
        variant = "count",
        size = UDim2.fromScale(0, 0.055),
        layoutOrder = 3,
    }),
}))
