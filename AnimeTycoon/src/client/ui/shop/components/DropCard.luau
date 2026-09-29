--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local PromoBadge = require(script.Parent.PromoBadge)
local StrokeText = require(script.Parent.StrokeText)
local theme = require(script.Parent.Parent.Parent.theme)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)
local useLayout = require(script.Parent.Parent.Parent.hooks.useLayout)

export type Props = {
    drop: types.DropPreview,
    layoutOrder: number?,
}

local RARITY_COLOR: { [string]: Color3 } = {
    common = Color3.fromRGB(40, 40, 40),
    rare = Color3.fromRGB(60, 120, 255),
    legendary = Color3.fromRGB(255, 190, 40),
    limited = Color3.fromRGB(200, 80, 255),
}

local function DropCard(props: Props): React.Node
    local layout = useLayout()
    local drop = props.drop
    local border = RARITY_COLOR[drop.rarity] or RARITY_COLOR.common
    local w = layout.px(72)
    local h = layout.px(100)

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = theme.Colors.bg3,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
    }, {
        Stroke = React.createElement("UIStroke", {
            Color = border,
            Thickness = if drop.rarity == "limited" then 0.08 else tokens.strokeCard,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
        -- Stub portrait
        Art = React.createElement("Frame", {
            Size = UDim2.new(1, -layout.gap(8), 0.55, 0),
            Position = UDim2.new(0.5, 0, 0, layout.gap(6)),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = theme.Colors.bg4,
            BorderSizePixel = 0,
        }),
        Value = React.createElement(StrokeText, {
            text = drop.valueText,
            textSize = 10,
            color = Color3.fromRGB(100, 230, 90),
            size = UDim2.new(1, -4, 0, layout.px(14)),
            position = UDim2.new(0.5, 0, 1, -layout.px(28)),
            anchorPoint = Vector2.new(0.5, 1),
        }),
        Chance = React.createElement(StrokeText, {
            text = drop.chanceText,
            textSize = 11,
            size = UDim2.new(1, -4, 0, layout.px(14)),
            position = UDim2.new(0.5, 0, 1, -layout.gap(4)),
            anchorPoint = Vector2.new(0.5, 1),
        }),
        Badge = if drop.rarity == "limited"
            then React.createElement(PromoBadge, {
                text = "LIMITED!",
                position = UDim2.new(0.5, 0, 0, -layout.px(4)),
                anchorPoint = Vector2.new(0.5, 0),
                rotation = 0,
            })
            else nil,
    })
end

return DropCard
