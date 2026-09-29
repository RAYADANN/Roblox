--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local StrokeText = require(script.Parent.StrokeText)
local tokens = require(script.Parent.Parent.tokens)

export type Props = {
    price: number,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
    layoutOrder: number?,
}

local function SalePrice(props: Props): React.Node
    return React.createElement("Frame", {
        Size = props.size or UDim2.fromScale(1, 0.3),
        Position = props.position,
        AnchorPoint = props.anchorPoint,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ZIndex = 4,
    }, {
        Label = React.createElement(StrokeText, {
            text = tostring(props.price),
            color = tokens.saleRed,
            strokeThickness = tokens.strokeBtn,
            size = UDim2.fromScale(1, 1),
        }),
        Strike = React.createElement("Frame", {
            Size = UDim2.fromScale(0.55, 0.2),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = tokens.titleShadow,
            BorderSizePixel = 0,
            ZIndex = 5,
            Rotation = -12,
        }),
    })
end

return SalePrice
