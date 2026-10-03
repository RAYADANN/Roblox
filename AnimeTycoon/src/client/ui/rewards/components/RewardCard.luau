--!strict
-- Reward card: money icon or 3D case + live timer + hover.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MockData = require(script.Parent.Parent.MockData)
local RewardCaseViewport = require(script.Parent.RewardCaseViewport)
local RewardTimerLogic =
    require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("util").RewardTimerLogic)
local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    item: types.RewardItem,
    position: UDim2,
    size: UDim2?,
    claimable: boolean,
    layoutOrder: number?,
    onClaim: ((id: string, from: Vector2) -> ())?,
}

local function nowSec(): number
    return math.floor(workspace:GetServerTimeNow())
end

local function RewardCard(props: Props): React.Node
    local C = SG.card
    local item = props.item
    local claimed = item.claimed == true
    local claimable = props.claimable and not claimed
    local isCase = item.rewardType == "case" and typeof(item.boxModelName) == "string"

    local remaining, setRemaining = React.useState(function()
        return RewardTimerLogic.remaining(item.unlockAt, nowSec())
    end)

    React.useEffect(function()
        if claimed then
            return
        end
        setRemaining(RewardTimerLogic.remaining(item.unlockAt, nowSec()))
        local acc = 0
        local conn = RunService.Heartbeat:Connect(function(dt)
            acc += dt
            if acc < 0.25 then
                return
            end
            acc = 0
            setRemaining(RewardTimerLogic.remaining(item.unlockAt, nowSec()))
        end)
        return function()
            conn:Disconnect()
        end
    end, { item.unlockAt, claimed })

    local hoverScale, handlers = useHoverPress({
        hoverScale = if claimable then 1.1 else 1.05,
        disabled = claimed,
    })
    local visualScale = if claimed then 1 else hoverScale

    local subtitleText = if claimed
        then "CLAIMED!"
        elseif claimable then "CLAIM!"
        else RewardTimerLogic.format(remaining)

    local strokeColor = if claimable then tokens.claimGlow else tokens.titleShadow
    local strokeThickness = if claimable then tokens.strokeCardClaimable else tokens.strokeCard

    local visual: React.Node
    if isCase then
        visual = React.createElement(RewardCaseViewport, {
            boxModelName = item.boxModelName :: string,
            mutation = item.mutation,
            size = C.case.size,
            position = C.case.pos,
            anchorPoint = C.case.anchor,
            zIndex = 2,
            dimmed = claimed,
        })
    else
        visual = React.createElement("ImageLabel", {
            Size = C.icon.size,
            Position = C.icon.pos,
            AnchorPoint = C.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = item.icon or assets.cardIcon,
            ImageTransparency = if claimed then 0.3 else 0,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 2,
        })
    end

    return React.createElement("ImageButton", {
        Size = props.size or SG.grid.cardSize,
        Position = props.position,
        AnchorPoint = SG.grid.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        AutoButtonColor = false,
        ZIndex = if claimable then 4 else 2,
        LayoutOrder = props.layoutOrder,
        Active = claimable,
        [React.Event.Activated] = if claimable and props.onClaim
            then function(rbx: ImageButton)
                local pos = rbx.AbsolutePosition
                local size = rbx.AbsoluteSize
                props.onClaim(item.id, Vector2.new(pos.X + size.X * 0.5, pos.Y + size.Y * 0.5))
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
                ImageTransparency = if claimed then 0.2 else 0,
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 1,
            }, {
                Stroke = React.createElement("UIStroke", {
                    Color = strokeColor,
                    Thickness = strokeThickness,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
            }),
            Visual = visual,
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

return RewardCard
