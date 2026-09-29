--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local StrokeText = require(script.Parent.StrokeText)
local tokens = require(script.Parent.Parent.tokens)
local useLayout = require(script.Parent.Parent.Parent.hooks.useLayout)

export type Props = {
    text: string,
    position: UDim2?,
    anchorPoint: Vector2?,
    rotation: number?,
    layoutOrder: number?,
    zIndex: number?,
}

local function PromoBadge(props: Props): React.Node
    local layout = useLayout()

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(layout.px(110), layout.px(28)),
        Position = props.position or UDim2.new(1, -layout.gap(8), 0, layout.gap(6)),
        AnchorPoint = props.anchorPoint or Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Rotation = props.rotation or 8,
        LayoutOrder = props.layoutOrder,
        ZIndex = props.zIndex or 5,
    }, {
        Label = React.createElement(StrokeText, {
            text = props.text,
            color = tokens.badgeRed,
            strokeThickness = tokens.strokeText,
            size = UDim2.fromScale(1, 1),
        }),
    })
end

return PromoBadge
