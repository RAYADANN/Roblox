--!strict
-- Deprecated stub panel — prefer image cards from StarterGui assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local tokens = require(script.Parent.Parent.tokens)

export type Props = {
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
    color: Color3?,
    layoutOrder: number?,
    zIndex: number?,
    clipsDescendants: boolean?,
    children: React.Node?,
}

local function StudPanel(props: Props): React.Node
    return React.createElement("Frame", {
        Size = props.size or UDim2.fromScale(1, 1),
        Position = props.position,
        AnchorPoint = props.anchorPoint,
        BackgroundColor3 = props.color or Color3.fromRGB(210, 190, 150),
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ZIndex = props.zIndex or 1,
        ClipsDescendants = props.clipsDescendants == true,
    }, {
        Stroke = React.createElement("UIStroke", {
            Color = tokens.titleShadow,
            Thickness = tokens.strokeCard,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
        Body = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, props.children),
    })
end

return StudPanel
