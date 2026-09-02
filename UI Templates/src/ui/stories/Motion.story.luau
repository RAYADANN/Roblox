--!strict
-- Six buttons, six Flipper motions. Soft springs by default.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MotionButton = require(script.Parent.Parent.components.MotionButton)
local OutlinedText = require(script.Parent.Parent.components.OutlinedText)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

type Row = {
    motion: MotionButton.MotionKind,
    label: string,
    hint: string,
    tone: theme.ActionTone,
}

local rows: { Row } = {
    { motion = "soft", label = "SOFT", hint = "Hover — плавный scale", tone = "buy" },
    { motion = "pop", label = "POP", hint = "Hover/press — пружинка", tone = "equip" },
    {
        motion = "tilt",
        label = "TILT",
        hint = "Hover — лёгкий наклон",
        tone = "close",
    },
    { motion = "lift", label = "LIFT", hint = "Hover — поднимается", tone = "buy" },
    {
        motion = "shake",
        label = "SHAKE",
        hint = "Click — покачивание",
        tone = "equip",
    },
    { motion = "slide", label = "SLIDE", hint = "Mount — въезд слева", tone = "close" },
}

local children: { [string]: React.Node } = {
    Pad = React.createElement("UIPadding", {
        PaddingTop = UDim.new(0, 28),
        PaddingBottom = UDim.new(0, 28),
        PaddingLeft = UDim.new(0, 28),
        PaddingRight = UDim.new(0, 28),
    }),
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    Title = React.createElement(OutlinedText, {
        text = "BUTTON MOTIONS",
        variant = "title",
        size = UDim2.new(1, 0, 0, 42),
        pulse = false,
        layoutOrder = 0,
    }),
    Sub = React.createElement(OutlinedText, {
        text = "Flipper · soft springs — hover / click each",
        variant = "body",
        size = UDim2.new(1, 0, 0, 28),
        pulse = false,
        layoutOrder = 1,
    }),
}

for i, row in rows do
    children["Row" .. i] = React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1,
        LayoutOrder = i + 1,
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 16),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Btn = React.createElement(MotionButton, {
            motion = row.motion,
            label = row.label,
            tone = row.tone,
            size = UDim2.fromOffset(200, 52),
            appearDelay = 0.04 * i,
            layoutOrder = 1,
        }),
        Hint = React.createElement(OutlinedText, {
            text = row.hint,
            variant = "body",
            size = UDim2.new(1, -220, 0, 28),
            pulse = false,
            layoutOrder = 2,
        }),
    })
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
