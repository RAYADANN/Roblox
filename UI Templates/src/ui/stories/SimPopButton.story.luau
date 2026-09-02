--!strict
-- SimPop palette: all tones × orientations.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SimPopKit = require(script.Parent.Parent.simpop)
local SimPopButton = SimPopKit.SimPopButton
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local tones = SimPopKit.ImageIds.TONES
local orientations = SimPopKit.ImageIds.ORIENTATIONS

local ImageIdsModule = SimPopKit.ImageIds

local function nativeSize(
    tone: ImageIdsModule.SimPopTone,
    orientation: ImageIdsModule.SimPopOrientation
): Vector2
    local chrome = SimPopKit.SimPop[tone][orientation]
    return Vector2.new(chrome.nativeWidth, chrome.nativeHeight)
end

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
        local size = nativeSize(tone, orientation)
        rowChildren[tone] = React.createElement(SimPopButton, {
            tone = tone,
            orientation = orientation,
            size = UDim2.fromOffset(size.X, size.Y),
            appearDelay = 0.04 * order,
            layoutOrder = ti,
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
    BackgroundColor3 = theme.Colors.bg,
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, rows))
