--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SimPop = require(script.Parent.Parent.simpop)
local BlueButton = SimPop.BlueButton
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

return mount(React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg,
    BorderSizePixel = 0,
}, {
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, theme.Space.lg),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    Large = React.createElement(BlueButton, {
        label = "PLAY",
        size = UDim2.fromOffset(330, 106),
        layoutOrder = 1,
    }),
    Medium = React.createElement(BlueButton, {
        label = "EQUIP",
        size = UDim2.fromOffset(220, 70),
        appearDelay = 0.08,
        layoutOrder = 2,
    }),
    Small = React.createElement(BlueButton, {
        label = "BUY",
        size = UDim2.fromOffset(160, 52),
        appearDelay = 0.16,
        layoutOrder = 3,
    }),
}))
