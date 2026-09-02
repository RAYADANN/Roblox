--!strict
-- Hoarcekat: SimPop tone × orientation grid.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SimPopKit = require(script.Parent.Parent.simpop)
local SimPopButton = SimPopKit.SimPopButton
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local tones = SimPopKit.TONES
local orientations = SimPopKit.ORIENTATIONS

local rows: { [string]: React.Node } = {
    Pad = React.createElement("UIPadding", {
        PaddingTop = UDim.new(0, theme.Space.lg),
        PaddingBottom = UDim.new(0, theme.Space.lg),
        PaddingLeft = UDim.new(0, theme.Space.lg),
        PaddingRight = UDim.new(0, theme.Space.lg),
    }),
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, theme.Space.lg),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
}

local order = 1
for _, orientation in orientations do
    local rowChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, theme.Space.md),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }
    for ti, tone in tones do
        local chrome = SimPopKit.SimPop[tone][orientation]
        rowChildren[tone] = React.createElement(SimPopButton, {
            tone = tone,
            orientation = orientation,
            size = UDim2.fromOffset(chrome.nativeWidth, chrome.nativeHeight),
            layoutOrder = ti,
            onActivated = function()
                print(`[SimPop] {tone} {orientation}`)
            end,
        })
    end
    rows[orientation] = React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 120),
        BackgroundTransparency = 1,
        LayoutOrder = order,
    }, rowChildren)
    order += 1
end

return mount(React.createElement("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg1,
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, rows))
