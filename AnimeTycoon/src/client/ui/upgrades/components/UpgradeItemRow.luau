--!strict
-- One upgrade row = StarterGui.Upgrade Home/Luck template (inside Items).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Formatters = require(script.Parent.Parent.Parent.util.Formatters)
local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.Parent.Parent.shop.components.StrokeText)
local UpgradeLogic = require(ReplicatedStorage.shared.util.UpgradeLogic)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    upgradeId: string,
    title: string,
    description: string,
    icon: string,
    level: number,
    coins: number,
    size: UDim2,
    layoutOrder: number,
    onBuyCoins: (upgradeId: string) -> (),
    onBuyRobux: ((upgradeId: string) -> ())?,
}

type PriceBtnProps = {
    image: string,
    size: UDim2,
    position: UDim2,
    label: string,
    showRobuxIcon: boolean?,
    disabled: boolean?,
    onActivated: () -> (),
}

local function PriceButton(props: PriceBtnProps): React.Node
    local scale, handlers = useHoverPress({})

    local face: React.Node
    if props.showRobuxIcon then
        face = React.createElement("Frame", {
            Size = SG.row.buttonLabel.size,
            Position = SG.row.buttonLabel.pos,
            AnchorPoint = SG.row.buttonLabel.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, {
            Icon = React.createElement("ImageLabel", {
                Size = SG.row.robuxIcon.size,
                Position = SG.row.robuxIcon.pos,
                AnchorPoint = SG.row.robuxIcon.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = assets.robuxIcon,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 4,
            }),
            Text = React.createElement(StrokeText, {
                text = props.label,
                strokeThickness = tokens.strokeText,
                size = SG.row.robuxText.size,
                position = SG.row.robuxText.pos,
                anchorPoint = SG.row.robuxText.anchor,
                zIndex = 4,
            }),
        })
    else
        face = React.createElement(StrokeText, {
            text = props.label,
            strokeThickness = tokens.strokeText,
            size = SG.row.buttonLabel.size,
            position = SG.row.buttonLabel.pos,
            anchorPoint = SG.row.buttonLabel.anchor,
            zIndex = 3,
        })
    end

    return React.createElement("ImageButton", {
        Size = props.size,
        Position = props.position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = props.image,
        ScaleType = Enum.ScaleType.Stretch,
        AutoButtonColor = false,
        Active = not props.disabled,
        ImageTransparency = if props.disabled then 0.25 else 0,
        ZIndex = 3,
        [React.Event.Activated] = if props.disabled
            then nil
            else function()
                props.onActivated()
            end,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Stroke = React.createElement("UIStroke", {
            Color = tokens.titleShadow,
            Thickness = tokens.strokeBtn,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
        Face = face,
    })
end

local function UpgradeItemRow(props: Props): React.Node
    local maxed = UpgradeLogic.isMaxLevel(props.upgradeId, props.level)
    local cost = UpgradeLogic.cost(props.upgradeId, props.level) or 0
    local robux = UpgradeLogic.robuxCost(props.upgradeId) or 0
    local canBuy = not maxed and props.coins >= cost
    local status = UpgradeLogic.statusText(props.upgradeId, props.level)
    local moneyLabel = if maxed then "MAX" else Formatters.money(cost)
    local robuxLabel = if maxed then "MAX" else tostring(robux)

    return React.createElement("Frame", {
        Size = props.size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
        BackGround = React.createElement("ImageLabel", {
            Size = SG.row.bg.size,
            Position = SG.row.bg.pos,
            AnchorPoint = SG.row.bg.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = assets.rowBg,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
        }, {
            Stroke = React.createElement("UIStroke", {
                Color = tokens.titleShadow,
                Thickness = tokens.strokeRow,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
        }),
        Icon = React.createElement("ImageLabel", {
            Size = SG.row.icon.size,
            Position = SG.row.icon.pos,
            AnchorPoint = SG.row.icon.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = props.icon,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 2,
        }, {
            -- Pad art fills the asset tighter than other icons — shrink so it stays in-row.
            Scale = if props.upgradeId == "pad"
                then React.createElement("UIScale", { Scale = 0.85 })
                else nil,
        }),
        Title = React.createElement(StrokeText, {
            text = props.title,
            strokeThickness = tokens.strokeText,
            size = SG.row.title.size,
            position = SG.row.title.pos,
            anchorPoint = SG.row.title.anchor,
            textXAlignment = Enum.TextXAlignment.Left,
            zIndex = 2,
        }),
        Desc = React.createElement(StrokeText, {
            text = props.description,
            color = tokens.desc,
            strokeThickness = tokens.strokeText,
            size = SG.row.desc.size,
            position = SG.row.desc.pos,
            anchorPoint = SG.row.desc.anchor,
            textXAlignment = Enum.TextXAlignment.Left,
            zIndex = 2,
        }),
        Current = React.createElement(StrokeText, {
            text = status,
            color = tokens.current,
            strokeThickness = tokens.strokeText,
            size = SG.row.current.size,
            position = SG.row.current.pos,
            anchorPoint = SG.row.current.anchor,
            textXAlignment = Enum.TextXAlignment.Left,
            zIndex = 2,
        }),
        Money = React.createElement(PriceButton, {
            image = assets.moneyButton,
            size = SG.row.money.size,
            position = SG.row.money.pos,
            label = moneyLabel,
            disabled = maxed or not canBuy,
            onActivated = function()
                props.onBuyCoins(props.upgradeId)
            end,
        }),
        Robux = React.createElement(PriceButton, {
            image = assets.robuxButton,
            size = SG.row.robux.size,
            position = SG.row.robux.pos,
            label = robuxLabel,
            showRobuxIcon = not maxed,
            disabled = maxed,
            onActivated = function()
                if props.onBuyRobux then
                    props.onBuyRobux(props.upgradeId)
                end
            end,
        }),
    })
end

return UpgradeItemRow
