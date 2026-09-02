--!strict
-- All tone × shine PNG chrome (9 variants).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ActionButton = require(script.Parent.Parent.components.ActionButton)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local tones: { theme.ActionTone } = { "buy", "equip", "close" }
local shines: { theme.Shine } = { "linear", "radial", "diamond" }

local children: { [string]: React.Node } = {
    Pad = React.createElement("UIPadding", {
        PaddingTop = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20),
        PaddingBottom = UDim.new(0, 20),
    }),
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
}

local order = 1
for _, shine in shines do
    local rowChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 12),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for ti, tone in tones do
        rowChildren[tone] = React.createElement(ActionButton, {
            tone = tone,
            shine = shine,
            size = UDim2.fromOffset(200, 52),
            appearDelay = 0.04 * order,
            layoutOrder = ti,
        })
    end
    children[shine] = React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        LayoutOrder = order,
    }, rowChildren)
    order += 1
end

return mount(React.createElement("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg,
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, children))
