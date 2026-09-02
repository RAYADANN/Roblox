--!strict
-- 120 BlueButtons in ScrollingFrame — shine via shared driver + visibility gate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SimPop = require(script.Parent.Parent.simpop)
local SimPopButton = SimPop.SimPopButton
local SimPopImageIds = SimPop.ImageIds
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local SLOT_COUNT = 120
local COLUMNS = 4

local function pickTone(i: number): SimPopImageIds.SimPopTone
    return SimPopImageIds.TONES[((i - 1) % #SimPopImageIds.TONES) + 1]
end

local function pickOrientation(i: number): SimPopImageIds.SimPopOrientation
    return SimPopImageIds.ORIENTATIONS[((i - 1) % #SimPopImageIds.ORIENTATIONS) + 1]
end

local function BlueButtonGridStory(): React.Node
    local scrollRef = React.useRef(nil :: ScrollingFrame?)

    local slots: { [string]: React.Node } = {
        Pad = React.createElement("UIPadding", {
            PaddingTop = UDim.new(0, theme.Space.lg),
            PaddingBottom = UDim.new(0, theme.Space.lg),
            PaddingLeft = UDim.new(0, theme.Space.lg),
            PaddingRight = UDim.new(0, theme.Space.lg),
        }),
        Grid = React.createElement("UIGridLayout", {
            CellSize = UDim2.fromOffset(280, 90),
            CellPadding = UDim2.fromOffset(theme.Space.md, theme.Space.md),
            FillDirectionMaxCells = COLUMNS,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }

    for i = 1, SLOT_COUNT do
        slots[`Btn{i}`] = React.createElement(SimPopButton, {
            tone = pickTone(i),
            orientation = pickOrientation(i),
            label = `ITEM {i}`,
            size = UDim2.fromScale(1, 1),
            layoutOrder = i,
            appearDelay = 0,
            scrollRef = scrollRef,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.bg,
        BorderSizePixel = 0,
    }, {
        Scroll = React.createElement("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 6,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ref = function(inst: ScrollingFrame?)
                scrollRef.current = inst
            end,
        }, slots),
    })
end

return mount(React.createElement(BlueButtonGridStory))
