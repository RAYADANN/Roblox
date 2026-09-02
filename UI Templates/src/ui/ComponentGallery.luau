--!strict
-- Component gallery (Hoarcekat Gallery.story). Play uses App = Inventory.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ActionButton = require(script.Parent.components.ActionButton)
local CloseButton = require(script.Parent.components.CloseButton)
local GradientBar = require(script.Parent.components.GradientBar)
local OutlinedText = require(script.Parent.components.OutlinedText)
local SimPop = require(script.Parent.simpop)
local SimPopButton = SimPop.SimPopButton
local SimPopBlock = SimPop.block.SimPopBlock
local Slot = require(script.Parent.components.Slot)
local theme = require(script.Parent.theme)

local function Section(props: {
    title: string,
    layoutOrder: number,
    children: { [string]: React.Node },
}): React.Node
    local rowChildren: { [string]: React.Node } = {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(theme.Space.gap, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Wraps = true,
        }),
    }
    for name, child in props.children do
        rowChildren[name] = child
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = props.layoutOrder,
    }, {
        Layout = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(theme.Space.gap, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
        Title = React.createElement(OutlinedText, {
            text = props.title,
            variant = "body",
            size = UDim2.new(1, 0, 0, 28),
            layoutOrder = 1,
        }),
        Row = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, rowChildren),
    })
end

local function ComponentGallery(): React.Node
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
        }, {
            Pad = React.createElement("UIPadding", {
                PaddingTop = UDim.new(theme.Space.pad, 0),
                PaddingBottom = UDim.new(theme.Space.pad, 0),
                PaddingLeft = UDim.new(theme.Space.pad, 0),
                PaddingRight = UDim.new(theme.Space.pad, 0),
            }),
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(theme.Space.sectionGap, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),

            Header = React.createElement("Frame", {
                Size = UDim2.fromScale(1, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Vertical,
                    Padding = UDim.new(theme.Space.gap, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                Title = React.createElement(OutlinedText, {
                    text = "INVENTORY",
                    variant = "title",
                    size = UDim2.new(1, 0, 0, 48),
                    layoutOrder = 1,
                }),
                Subtitle = React.createElement(OutlinedText, {
                    text = "DEFAULT TEXT",
                    variant = "body",
                    size = UDim2.new(1, 0, 0, 32),
                    layoutOrder = 2,
                }),
                Count = React.createElement(OutlinedText, {
                    text = "1/415",
                    variant = "count",
                    size = UDim2.new(1, 0, 0, 36),
                    layoutOrder = 3,
                }),
            }),

            -- All PNG chrome: buy/equip/close × linear (sizes differ on purpose)
            Actions = React.createElement(Section, {
                title = "Action buttons (PNG chrome)",
                layoutOrder = 2,
                children = {
                    BuyLarge = React.createElement(ActionButton, {
                        tone = "buy",
                        shine = "linear",
                        size = UDim2.new(0.22, 0, 0, 56),
                        appearDelay = 0.05,
                        layoutOrder = 1,
                    }),
                    Equip = React.createElement(ActionButton, {
                        tone = "equip",
                        shine = "radial",
                        size = UDim2.new(0.16, 0, 0, 48),
                        appearDelay = 0.12,
                        layoutOrder = 2,
                    }),
                    CloseSmall = React.createElement(ActionButton, {
                        tone = "close",
                        shine = "diamond",
                        size = UDim2.new(0.12, 0, 0, 40),
                        appearDelay = 0.2,
                        layoutOrder = 3,
                    }),
                },
            }),

            ChromeGrid = React.createElement(Section, {
                title = "All shines (linear / radial / diamond)",
                layoutOrder = 3,
                children = {
                    BuyR = React.createElement(ActionButton, {
                        tone = "buy",
                        shine = "radial",
                        size = UDim2.fromOffset(180, 48),
                        appearDelay = 0.22,
                        layoutOrder = 1,
                    }),
                    EquipD = React.createElement(ActionButton, {
                        tone = "equip",
                        shine = "diamond",
                        size = UDim2.fromOffset(180, 48),
                        appearDelay = 0.26,
                        layoutOrder = 2,
                    }),
                    CloseL = React.createElement(ActionButton, {
                        tone = "close",
                        shine = "linear",
                        size = UDim2.fromOffset(180, 48),
                        appearDelay = 0.3,
                        layoutOrder = 3,
                    }),
                },
            }),

            SimPopButtons = React.createElement(Section, {
                title = "SimPop buttons (tone × orientation)",
                layoutOrder = 4,
                children = {
                    GreenH = React.createElement(SimPopButton, {
                        tone = "green",
                        orientation = "horizontal",
                        size = UDim2.fromOffset(260, 82),
                        appearDelay = 0.32,
                        layoutOrder = 1,
                    }),
                    OrangeV = React.createElement(SimPopButton, {
                        tone = "orange",
                        orientation = "vertical",
                        size = UDim2.fromOffset(240, 76),
                        appearDelay = 0.36,
                        layoutOrder = 2,
                    }),
                    RedH = React.createElement(SimPopButton, {
                        tone = "red",
                        orientation = "horizontal",
                        size = UDim2.fromOffset(260, 82),
                        appearDelay = 0.4,
                        layoutOrder = 3,
                    }),
                },
            }),

            SimPopBlocks = React.createElement(Section, {
                title = "SimPop blocks (shop / inventory cards)",
                layoutOrder = 5,
                children = {
                    Card = React.createElement(SimPopBlock, {
                        size = UDim2.fromOffset(140, 192),
                        appearDelay = 0.42,
                        layoutOrder = 1,
                        children = {
                            Title = React.createElement("TextLabel", {
                                Size = UDim2.fromScale(1, 0.2),
                                Position = UDim2.fromScale(0.5, 0.55),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                BackgroundTransparency = 1,
                                Text = "ITEM",
                                Font = theme.Font.display,
                                TextScaled = true,
                                TextColor3 = theme.Colors.white,
                            }, {
                                Outline = React.createElement("UIStroke", {
                                    Color = theme.Colors.black,
                                    Thickness = theme.Stroke.text,
                                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                                }),
                            }),
                        },
                    }),
                },
            }),

            Closes = React.createElement(Section, {
                title = "Close X",
                layoutOrder = 6,
                children = {
                    X = React.createElement(CloseButton, {
                        shine = "linear",
                        size = UDim2.fromOffset(56, 56),
                        appearDelay = 0.32,
                        layoutOrder = 1,
                    }),
                },
            }),

            Bars = React.createElement(Section, {
                title = "Bars (Flipper fill)",
                layoutOrder = 7,
                children = {
                    Teal = React.createElement(GradientBar, {
                        tone = "teal",
                        size = UDim2.new(0.4, 0, 0, 28),
                        progress = 0.78,
                        appearDelay = 0.35,
                        layoutOrder = 1,
                    }),
                    Orange = React.createElement(GradientBar, {
                        tone = "orange",
                        size = UDim2.new(0.4, 0, 0, 28),
                        progress = 0.42,
                        appearDelay = 0.45,
                        layoutOrder = 2,
                    }),
                },
            }),

            Slots = React.createElement(Section, {
                title = "Slots",
                layoutOrder = 8,
                children = {
                    Purple = React.createElement(Slot, {
                        rarity = "purple",
                        size = UDim2.fromOffset(96, 96),
                        appearDelay = 0.4,
                        layoutOrder = 1,
                    }),
                    Gold = React.createElement(Slot, {
                        rarity = "gold",
                        size = UDim2.fromOffset(96, 96),
                        appearDelay = 0.5,
                        layoutOrder = 2,
                    }),
                    Blue = React.createElement(Slot, {
                        rarity = "blue",
                        size = UDim2.fromOffset(96, 96),
                        appearDelay = 0.6,
                        layoutOrder = 3,
                    }),
                },
            }),
        }),
    })
end

return ComponentGallery
