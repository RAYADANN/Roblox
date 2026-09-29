--!strict
-- Кнопка: цена и скидка — отдельные блоки (свои size/pos).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local StrokeText = require(script.Parent.StrokeText)
local assets = require(script.Parent.Parent.assets)
local tokens = require(script.Parent.Parent.tokens)
local useHoverPress = require(script.Parent.Parent.Parent.hooks.useHoverPress)

export type Props = {
    price: number,
    originalPrice: number?,
    onActivated: () -> (),
    disabled: boolean?,
    layoutOrder: number?,
    variant: string?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
}

-- Основная цена (Robux + число). Ширина — AutomaticSize по тексту.
local PRICE = {
    size = UDim2.fromScale(0, 1),
    pos = UDim2.fromScale(0.5, 0.45),
    anchor = Vector2.new(0.5, 0.5),
    gap = 0,
}

-- Скидка отдельно: крути size/pos здесь, не в PRICE.
local SALE = {
    size = UDim2.fromScale(0, 0.5),
    pos = UDim2.fromScale(0.6, 0),
    anchor = Vector2.new(0.5, 0.5),
    gap = 0,
    strikeH = 0.14,
    strikeRot = -12,
}

local function buyImage(variant: string?): string
    if variant == "yellow" then
        return assets.buyYellow
    elseif variant == "pink" then
        return assets.buyPink
    elseif variant == "money" then
        return assets.buyMoney
    end
    return assets.buttonFace
end

local function robuxRow(opts: {
    text: string,
    color: Color3?,
    iconColor: Color3?,
    gap: number,
    zIndex: number,
}): React.Node
    return React.createElement("Frame", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(1, 1),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = opts.zIndex,
    }, {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(opts.gap, 0),
        }),
        Icon = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = assets.robux,
            ImageColor3 = opts.iconColor or Color3.fromRGB(255, 255, 255),
            ScaleType = Enum.ScaleType.Crop,
            LayoutOrder = 1,
            ZIndex = opts.zIndex,
        }, {
            Aspect = React.createElement("UIAspectRatioConstraint", {
                AspectRatio = 1,
                DominantAxis = Enum.DominantAxis.Height,
            }),
        }),
        Label = React.createElement(StrokeText, {
            text = opts.text,
            color = opts.color,
            strokeThickness = tokens.strokeBtn,
            size = UDim2.fromScale(0, 1),
            automaticSize = Enum.AutomaticSize.X,
            textWrapped = false,
            textXAlignment = Enum.TextXAlignment.Left,
            layoutOrder = 2,
            zIndex = opts.zIndex,
        }),
    })
end

local function RobuxButton(props: Props): React.Node
    local disabled = props.disabled == true
    local scale, handlers = useHoverPress({ disabled = disabled })
    local hasSale = props.originalPrice ~= nil

    return React.createElement("ImageButton", {
        Size = props.size or UDim2.fromScale(0.4, 0.22),
        Position = props.position,
        AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = buyImage(props.variant),
        ImageTransparency = if disabled then 0.45 else 0,
        ScaleType = Enum.ScaleType.Stretch,
        AutoButtonColor = false,
        ClipsDescendants = false,
        LayoutOrder = props.layoutOrder,
        ZIndex = 3,
        [React.Event.Activated] = if disabled then nil else props.onActivated,
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

        -- Скидка: отдельный блок, размеры = SALE.*
        Sale = if hasSale
            then React.createElement("Frame", {
                AutomaticSize = Enum.AutomaticSize.X,
                Size = SALE.size,
                Position = SALE.pos,
                AnchorPoint = SALE.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, {
                Row = robuxRow({
                    text = tostring(props.originalPrice :: number),
                    color = tokens.saleRed,
                    iconColor = tokens.saleRed,
                    gap = SALE.gap,
                    zIndex = 4,
                }),
                Strike = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, SALE.strikeH),
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = tokens.titleShadow,
                    BorderSizePixel = 0,
                    Rotation = SALE.strikeRot,
                    ZIndex = 5,
                }),
            })
            else nil,

        -- Основная цена: размеры = PRICE.*
        Price = React.createElement("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = PRICE.size,
            Position = PRICE.pos,
            AnchorPoint = PRICE.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, {
            Row = robuxRow({
                text = tostring(props.price),
                gap = PRICE.gap,
                zIndex = 3,
            }),
        }),
    })
end

return RobuxButton
