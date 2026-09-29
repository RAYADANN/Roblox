--!strict
-- Day 7: «Day 7» слева, иконка+имя по центру, «OP!» справа.

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
    claimable: boolean,
    onClaim: ((id: string) -> ())?,
}

local function Day7Card(props: Props): React.Node
    local D = SG.day7
    local item = props.item
    local claimed = item.claimed == true
    local claimable = props.claimable and not claimed

    local hoverScale, handlers = useHoverPress({
        hoverScale = if claimable then 1.04 else 1.02,
        disabled = claimed or not claimable,
    })
    local visualScale = if claimed then 1 else hoverScale

    local strokeColor = if claimable then tokens.claimGlow else tokens.titleShadow
    local strokeThickness = if claimable then tokens.strokeCardClaimable else tokens.strokeCard

    return React.createElement("ImageButton", {
        Size = D.size,
        Position = D.pos,
        AnchorPoint = D.anchor,
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
                Image = MockData.backgroundFor("super"),
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
            DayLabel = React.createElement(StrokeText, {
                text = `Day {item.day}`,
                strokeThickness = tokens.strokeText,
                size = D.dayLabel.size,
                position = D.dayLabel.pos,
                anchorPoint = D.dayLabel.anchor,
                oversizedFit = true,
                zIndex = 3,
            }),
            Icon = React.createElement("ImageLabel", {
                Size = D.icon.size,
                Position = D.icon.pos,
                AnchorPoint = D.icon.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = item.icon or assets.cardIcon,
                ImageTransparency = if claimed then 0.25 else 0,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 2,
            }),
            Name = React.createElement(StrokeText, {
                text = item.valueText,
                strokeThickness = tokens.strokeText,
                size = D.name.size,
                position = D.name.pos,
                anchorPoint = D.name.anchor,
                zIndex = 3,
            }),
            Op = React.createElement(StrokeText, {
                text = item.opText or "OP!",
                strokeThickness = tokens.strokeText,
                size = D.op.size,
                position = D.op.pos,
                anchorPoint = D.op.anchor,
                oversizedFit = true,
                gradient = {
                    color = tokens.opGradient,
                    rotation = 90,
                },
                zIndex = 3,
            }),
        }),
    })
end

return Day7Card
