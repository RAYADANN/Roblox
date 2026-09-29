--!strict
-- Shop product card: gold SimPop plate + floating hero + Robux buy chip.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type LayoutKind = "pack" | "banner"

export type Props = {
    title: string,
    plateImage: string,
    heroImage: string?,
    shineWidth: number,
    price: number,
    kind: LayoutKind,
    description: string?,
    layoutOrder: number?,
    onBuy: (() -> ())?,
}

local P = theme.Layout.shop.product

local function outlinedText(kind: "title" | "body"): { [string]: React.Node }
    local isTitle = kind == "title"
    return {
        Outline = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            -- ScaledSize: thickness is fraction of text size (title=6 FixedSize was huge).
            Thickness = if isTitle then 0.1 else 0.08,
            Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            LineJoinMode = Enum.LineJoinMode.Round,
            StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        }),
    }
end

local function BuyButton(props: {
    price: number,
    onActivated: (() -> ())?,
}): React.Node
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.06,
        pressScale = 0.94,
    })

    return React.createElement("ImageButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Image = IconCatalog.ShopBuyGreen,
        ScaleType = Enum.ScaleType.Stretch,
        [React.Event.Activated] = function()
            if props.onActivated then
                props.onActivated()
            end
        end,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = hoverScale }),
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(0.22, 0),
        }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = P.buyStroke,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
        PriceCluster = React.createElement("Frame", {
            Size = UDim2.fromScale(0.9, P.buyPriceH),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ZIndex = 5,
        }, {
            Layout = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(P.buyCenterGap, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
            Price = React.createElement("TextLabel", {
                LayoutOrder = 1,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromScale(0, 1),
                BackgroundTransparency = 1,
                Text = tostring(props.price),
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 6,
            }, outlinedText("body")),
            Robux = React.createElement("ImageLabel", {
                LayoutOrder = 2,
                Size = UDim2.fromScale(P.buyRobuxH, P.buyRobuxH),
                BackgroundTransparency = 1,
                Image = IconCatalog.Robux,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 6,
            }, {
                Aspect = React.createElement("UIAspectRatioConstraint", {
                    AspectRatio = 1,
                }),
            }),
        }),
    })
end

local function FloatingHero(props: {
    image: string,
    kind: LayoutKind,
}): React.Node
    local baseY = if props.kind == "pack" then P.packHeroY else P.bannerHeroY
    local heroY, setHeroY = React.useBinding(baseY)

    React.useEffect(function()
        local t0 = os.clock()
        local conn = RunService.RenderStepped:Connect(function()
            local phase = (os.clock() - t0) * P.heroBobHz * math.pi * 2
            setHeroY(baseY + math.sin(phase) * P.heroBobAmp)
        end)
        return function()
            conn:Disconnect()
        end
    end, { baseY, P.heroBobAmp, P.heroBobHz })

    if props.kind == "pack" then
        return React.createElement("ImageLabel", {
            Size = UDim2.fromScale(P.packHeroW, P.packHeroH),
            Position = heroY:map(function(y: number)
                return UDim2.fromScale(0.5, y)
            end),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = props.image,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		})
	end

	return React.createElement("ImageLabel", {
		Size = UDim2.fromScale(P.bannerHeroW, P.bannerHeroH),
		Position = heroY:map(function(y: number)
			return UDim2.fromScale(P.bannerHeroX, y)
		end),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = props.image,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 2,
	})
end

local function ShopProductCard(props: Props): React.Node
    local kind: LayoutKind = props.kind
    local buyW = if kind == "pack" then P.packBuyW else P.bannerBuyW
    local buyH = if kind == "pack" then P.packBuyH else P.bannerBuyH
    local buyX = if kind == "pack" then P.packBuyX else P.bannerBuyX
    local buyY = if kind == "pack" then P.packBuyY else P.bannerBuyY
    local buyAnchor = if kind == "pack" then Vector2.new(0.5, 1) else Vector2.new(1, 1)

    local shineRef = shine.useShineRef({
        enabled = true,
        intervalSec = 2.2,
        positionY = 0.5,
        shineWidth = props.shineWidth,
    })

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
		Plate = React.createElement("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.Colors.indexCard,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Image = props.plateImage,
			ScaleType = Enum.ScaleType.Stretch,
			ClipsDescendants = false,
			ZIndex = 1,
		}, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(0.06, 0),
            }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = 4,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            ShineClip = React.createElement("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Active = false,
                ZIndex = 3,
            }, {
                Shine = React.createElement("ImageLabel", {
                    Size = UDim2.new(props.shineWidth, 0, 1.08, 0),
                    Position = UDim2.new(shine.startX(props.shineWidth), 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Image = IconCatalog.Shine,
                    ImageTransparency = 0.18,
                    ScaleType = Enum.ScaleType.Stretch,
                    ZIndex = 3,
                    ref = shineRef,
                }),
            }),
            Hero = if props.heroImage and props.heroImage ~= ""
                then React.createElement(FloatingHero, {
                    image = props.heroImage,
                    kind = kind,
                })
                else nil,
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromScale(
                    if kind == "banner" then P.titleW else 0.9,
                    if kind == "banner" then P.bannerTitleH else P.titleH
                ),
                Position = if kind == "pack"
                    then UDim2.fromScale(0.5, P.titlePadY)
                    else UDim2.fromScale(P.titlePadX, P.titlePadY),
                AnchorPoint = if kind == "pack" then Vector2.new(0.5, 0) else Vector2.new(0, 0),
                BackgroundTransparency = 1,
                Text = if kind == "banner" then string.upper(props.title) else props.title,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                TextXAlignment = if kind == "pack"
                    then Enum.TextXAlignment.Center
                    else Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 5,
            }, outlinedText("title")),
            Desc = if kind == "banner" and props.description
                then React.createElement("TextLabel", {
                    Size = UDim2.fromScale(0.55, P.bannerDescH),
                    Position = UDim2.fromScale(P.titlePadX, P.bannerDescPadY),
                    BackgroundTransparency = 1,
                    Text = props.description,
                    Font = theme.Font.display,
                    TextScaled = true,
                    TextColor3 = theme.Colors.white,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextTransparency = 0.05,
                    ZIndex = 5,
                }, outlinedText("body"))
                else nil,
            Buy = React.createElement("Frame", {
                Size = UDim2.fromScale(buyW, buyH),
                Position = UDim2.fromScale(buyX, buyY),
                AnchorPoint = buyAnchor,
                BackgroundTransparency = 1,
                ZIndex = 6,
            }, {
                Btn = React.createElement(BuyButton, {
                    price = props.price,
                    onActivated = props.onBuy,
                }),
            }),
        }),
    })
end

return ShopProductCard
