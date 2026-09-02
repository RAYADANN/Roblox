--!strict
-- SimPop Block — shop row + inventory grid demo (all tones).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SimPopBlockKit = require(script.Parent.Parent.simpop.block)
local ImageIds = SimPopBlockKit.ImageIds
local SimPopBlock = SimPopBlockKit.SimPopBlock
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local CARD_W = 320
local CARD_H = 439
local tones = SimPopBlockKit.TONES

local function CardContent(
    props: { title: string, subtitle: string?, layoutOrder: number? }
): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0.04, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Title = React.createElement("TextLabel", {
            Size = UDim2.new(0.9, 0, 0.14, 0),
            BackgroundTransparency = 1,
            Text = props.title,
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            LayoutOrder = 1,
        }, {
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        }),
        Sub = if props.subtitle
            then React.createElement("TextLabel", {
                Size = UDim2.new(0.8, 0, 0.1, 0),
                BackgroundTransparency = 1,
                Text = props.subtitle,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.countWarm,
                LayoutOrder = 2,
            }, {
                Outline = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.text,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                }),
            })
            else nil,
    })
end

local shopOffers: { { tone: ImageIds.SimPopBlockTone, title: string, subtitle: string } } = {
    { tone = "blue", title = "GEM PACK", subtitle = "499 R$" },
    { tone = "green", title = "COINS", subtitle = "x10K" },
    { tone = "orange", title = "BOOST", subtitle = "24H" },
    { tone = "red", title = "LEGEND", subtitle = "RARE" },
}

local invSlots: { { tone: ImageIds.SimPopBlockTone, title: string } } = {
    { tone = "blue", title = "SWORD" },
    { tone = "green", title = "SHIELD" },
    { tone = "orange", title = "POTION" },
    { tone = "red", title = "BOW" },
    { tone = "green", title = "KEY" },
    { tone = "orange", title = "MAP" },
    { tone = "blue", title = "GEM" },
    { tone = "red", title = "CROWN" },
}

local shopRowChildren: { [string]: React.Node } = {
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, theme.Space.md),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
}

for i, offer in shopOffers do
    shopRowChildren["Offer" .. i] = React.createElement(SimPopBlock, {
        tone = offer.tone,
        size = UDim2.fromOffset(CARD_W * 0.45, CARD_H * 0.45),
        layoutOrder = i,
        appearDelay = 0.06 * (i - 1),
        onActivated = function() end,
        children = {
            Body = React.createElement(CardContent, {
                title = offer.title,
                subtitle = offer.subtitle,
            }),
        },
    })
end

local gridChildren: { [string]: React.Node } = {
    Pad = React.createElement("UIPadding", {
        PaddingBottom = UDim.new(0, theme.Space.lg),
    }),
    Layout = React.createElement("UIGridLayout", {
        CellSize = UDim2.fromOffset(140, 192),
        CellPadding = UDim2.fromOffset(theme.Space.md, theme.Space.md),
        FillDirectionMaxCells = 4,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
}

for i, slot in invSlots do
    gridChildren["Slot" .. i] = React.createElement(SimPopBlock, {
        tone = slot.tone,
        size = UDim2.fromScale(1, 1),
        layoutOrder = i,
        appearDelay = 0.05 * (i - 1),
        children = {
            Body = React.createElement(CardContent, { title = slot.title }),
        },
    })
end

return mount(React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = theme.Colors.bg,
    BorderSizePixel = 0,
}, {
    Layout = React.createElement("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, theme.Space.lg),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    Pad = React.createElement("UIPadding", {
        PaddingTop = UDim.new(0, theme.Space.lg),
        PaddingBottom = UDim.new(0, theme.Space.lg),
        PaddingLeft = UDim.new(0, theme.Space.lg),
        PaddingRight = UDim.new(0, theme.Space.lg),
    }),
    ShopTitle = React.createElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "SHOP",
        Font = theme.Font.display,
        TextScaled = true,
        TextColor3 = theme.Colors.white,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
    }, {
        Outline = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.text,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        }),
    }),
    ShopRow = React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, CARD_H * 0.5),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    }, shopRowChildren),
    Palette = React.createElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = table.concat(tones, " · "),
        Font = theme.Font.display,
        TextScaled = true,
        TextColor3 = theme.Colors.text,
        TextTransparency = 0.35,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 3,
    }),
    InvTitle = React.createElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "INVENTORY",
        Font = theme.Font.display,
        TextScaled = true,
        TextColor3 = theme.Colors.white,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 4,
    }, {
        Outline = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.text,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        }),
    }),
    Grid = React.createElement("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -160),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        LayoutOrder = 5,
    }, gridChildren),
}))
