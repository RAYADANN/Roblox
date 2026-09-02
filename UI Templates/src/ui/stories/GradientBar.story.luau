--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local GradientBar = require(script.Parent.Parent.components.GradientBar)
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
    Teal = React.createElement(GradientBar, {
        tone = "teal",
        size = UDim2.fromScale(0.5, 0.04),
        layoutOrder = 1,
    }),
    Orange = React.createElement(GradientBar, {
        tone = "orange",
        size = UDim2.fromScale(0.5, 0.04),
        layoutOrder = 2,
    }),
}))
