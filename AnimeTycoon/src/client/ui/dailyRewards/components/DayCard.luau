--!strict
-- День 1–6: value сверху, иконка, статус снизу (CLAIMED! / CLAIM! / Day N).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MockData = require(script.Parent.Parent.MockData)
local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    item: types.DailyRewardItem,
    position: UDim2,
    size: UDim2?,
    claimable: boolean,
    onClaim: ((id: string) -> ())?,
}

local function DayCard(props: Props): React.Node
    local C = SG.card
    local item = props.item
    local claimed = item.claimed == true
    local claimable = props.claimable and not claimed

    local hoverScale, handlers = useHoverPress({
        hoverScale = if claimable then 1.08 else 1.04,
        disabled = claimed or not claimable,
    })
    local visualScale = if claimed then 1 else hoverScale

    local subtitleText = if claimed
        then "CLAIMED!"
        elseif claimable then "CLAIM!"
        else `Day {item.day}`

    local strokeColor = if claimable then tokens.claimGlow else tokens.titleShadow
    local strokeThickness = if claimable then tokens.strokeCardClaimable else tokens.strokeCard

    return React.createElement("ImageButton", {
        Size = props.size or SG.grid.cardSize,
        Position = props.position,
        AnchorPoint = SG.grid.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        AutoButtonColor = false,
        ZIndex = if claimable then 4 else 2,
        Active = claimable,
        [React.Event.Activated] = if claimable and props.onClaim
            then function()
                props.onClaim(item.id)
            end
            else nil,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = visualScale }),
        Inner = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Bg = React.createElement("ImageLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = MockData.backgroundFor(item.kind),
                ImageTransparency = if claimed then 0.15 else 0,
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 1,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = strokeColor,
                    Thickness = strokeThickness,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
            }),
            Icon = React.createElement("ImageLabel", {
                Size = C.icon.size,
                Position = C.icon.pos,
                AnchorPoint = C.icon.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = item.icon or assets.cardIcon,
                ImageTransparency = if claimed then 0.25 else 0,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2,
            }),
            Value = React.createElement(StrokeText, {
                text = item.valueText,
                strokeThickness = tokens.strokeText,
                size = C.value.size,
                position = C.value.pos,
                anchorPoint = C.value.anchor,
                zIndex = 3,
            }),
            Subtitle = React.createElement(StrokeText, {
                text = subtitleText,
                color = if claimable then tokens.claimGlow else tokens.titleWhite,
                strokeThickness = tokens.strokeText,
                size = C.subtitle.size,
                position = C.subtitle.pos,
                anchorPoint = C.subtitle.anchor,
                zIndex = 3,
            }),
        }),
    })
end

return DayCard
