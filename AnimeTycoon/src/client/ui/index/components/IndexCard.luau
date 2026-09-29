--!strict
-- Index card = StarterGui NormalItem (Name / value / Mutation / Rare).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MockData = require(script.Parent.Parent.MockData)
local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)

export type Props = {
    item: types.IndexItem,
    layoutOrder: number,
    fillParent: boolean?,
}

local function IndexCard(props: Props): React.Node
    local item = props.item
    local unlocked = item.unlocked
    local C = SG.card

    return React.createElement("Frame", {
        Size = if props.fillParent then UDim2.fromScale(1, 1) else C.size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
        Bg = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = item.image or MockData.cardImage(item.tier),
            ScaleType = Enum.ScaleType.Stretch,
            ImageTransparency = if unlocked then 0 else 0.35,
            ZIndex = 1,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = tokens.titleShadow,
                Thickness = tokens.strokeCard,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
        }),
        Name = React.createElement(StrokeText, {
            text = if unlocked then item.name else "???",
            strokeThickness = tokens.strokeText,
            size = C.name.size,
            position = C.name.pos,
            anchorPoint = C.name.anchor,
            zIndex = 3,
        }),
        Value = React.createElement(StrokeText, {
            text = if unlocked then item.valueText else "???",
            color = if unlocked then tokens.titleWhite else tokens.muted,
            strokeThickness = tokens.strokeText,
            size = C.value.size,
            position = C.value.pos,
            anchorPoint = C.value.anchor,
            zIndex = 3,
            gradient = if unlocked
                then {
                    color = tokens.valueGradient.color,
                    rotation = tokens.valueGradient.rotation,
                }
                else nil,
        }),
        Mutation = React.createElement(StrokeText, {
            text = if unlocked then item.mutationText else "???",
            strokeThickness = tokens.strokeText,
            size = C.mutation.size,
            position = C.mutation.pos,
            anchorPoint = C.mutation.anchor,
            zIndex = 3,
        }),
        Rare = React.createElement(StrokeText, {
            text = if unlocked then item.rareText else "???",
            strokeThickness = tokens.strokeText,
            size = C.rare.size,
            position = C.rare.pos,
            anchorPoint = C.rare.anchor,
            zIndex = 3,
        }),
        Lock = if not unlocked
            then React.createElement("ImageLabel", {
                Size = C.lock.size,
                Position = C.lock.pos,
                AnchorPoint = C.lock.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = assets.lock,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 4,
            })
            else nil,
    })
end

return IndexCard
