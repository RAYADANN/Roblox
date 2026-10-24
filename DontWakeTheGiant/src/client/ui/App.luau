--!strict
-- HUD этапа 1 (GDD 11.1): шкала сна сверху, монеты слева, лента событий, карточка предмета, Sneak.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Button = require(script.Parent.components.Button)
local CarryCard = require(script.Parent.components.CarryCard)
local Formatters = require(script.Parent.util.Formatters)
local HudContext = require(script.Parent.context.HudContext)
local NoiseBar = require(script.Parent.components.NoiseBar)
local ResourceChip = require(script.Parent.components.ResourceChip)
local theme = require(script.Parent.theme)
local useLayout = require(script.Parent.hooks.useLayout)

local function App(): React.Node
    local layout = useLayout()
    local ctx = React.useContext(HudContext)

    local feedRows = {}
    for i, entry in ctx.feed do
        feedRows[`F{entry.id}`] = React.createElement("TextLabel", {
            LayoutOrder = i,
            Size = UDim2.new(1, 0, 0, layout.px(24)),
            BackgroundTransparency = 1,
            Text = entry.text,
            TextColor3 = entry.color,
            TextStrokeTransparency = 0.3,
            Font = theme.Font.title,
            TextSize = layout.text(18, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Coins = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(220), layout.px(70)),
            Position = UDim2.fromOffset(
                layout.safeLeft + layout.gap(12),
                layout.safeTop + layout.gap(12)
            ),
            BackgroundTransparency = 1,
        }, {
            List = React.createElement(
                "UIListLayout",
                { Padding = UDim.new(0, layout.gap(4)), SortOrder = Enum.SortOrder.LayoutOrder }
            ),
            Chip = React.createElement(ResourceChip, { amount = ctx.hud.coins, layoutOrder = 1 }),
            Income = React.createElement("TextLabel", {
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, layout.px(22)),
                BackgroundTransparency = 1,
                Text = `+{Formatters.shortNumber(ctx.hud.incomePerSec)}/s`,
                TextColor3 = theme.Colors.goldHi,
                TextStrokeTransparency = 0.3,
                Font = theme.Font.title,
                TextSize = layout.text(18, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
        }),
        Noise = React.createElement(NoiseBar, { noise = ctx.giant.noise, phase = ctx.giant.phase }),
        Feed = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(360), layout.px(110)),
            Position = UDim2.new(0, layout.safeLeft + layout.gap(12), 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
        }, {
            List = React.createElement("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
            Rows = React.createElement(React.Fragment, nil, feedRows),
        }),
        Carry = if ctx.carryingItemId
            then React.createElement(CarryCard, { itemId = ctx.carryingItemId, onDrop = ctx.drop })
            else nil,
        Sneak = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(150), layout.touch(56)),
            Position = UDim2.new(1, -layout.gap(16), 1, -layout.px(150)),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
        }, {
            Button = React.createElement(Button, {
                label = if ctx.sneaking then "SNEAKING" else "SNEAK",
                variant = if ctx.sneaking then "sell" else "secondary",
                onActivated = ctx.toggleSneak,
            }),
        }),
    })
end

return App
