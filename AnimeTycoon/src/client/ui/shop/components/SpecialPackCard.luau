--!strict
-- SpecialPack = StarterGui.Shop.Window.SpecialPack (GamePass категория).
-- Sheen / bg gradient sweep (no scale pulse).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local GiftButton = require(script.Parent.GiftButton)
local RobuxButton = require(script.Parent.RobuxButton)
local SG = require(script.Parent.Parent.layout)
local StrokeText = require(script.Parent.StrokeText)
local tokens = require(script.Parent.Parent.tokens)
local types = require(script.Parent.Parent.types)

export type Props = {
    offer: types.GamepassOffer,
    onBuy: (productId: string) -> (),
    onGift: ((productId: string) -> ())?,
    layoutOrder: number?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
}

local SHEEN_PERIOD = 2.8
local TITLE_SWEEP = 2.4

local function SpecialPackCard(props: Props): React.Node
    local offer = props.offer
    local P = SG.specialPack
    local icons = offer.icons or {}
    local buyVariant = offer.buyVariant or "special"

    local bgGradRef = React.useRef(nil :: UIGradient?)
    local bgImageGradRef = React.useRef(nil :: UIGradient?)
    local sheenRef = React.useRef(nil :: UIGradient?)
    local titleGradRef = React.useRef(nil :: UIGradient?)

    React.useEffect(function()
        local t0 = os.clock()
        local conn = RunService.RenderStepped:Connect(function()
            local now = os.clock() - t0

            local uBg = ((now / (SHEEN_PERIOD * 1.35)) % 1) * 2 - 1
            local rotBg = -12 + 8 * math.sin(now * 0.7)
            for _, grad in { bgGradRef.current, bgImageGradRef.current } do
                if grad then
                    grad.Offset = Vector2.new(uBg, 0)
                    grad.Rotation = rotBg
                end
            end

            local sheen = sheenRef.current
            if sheen then
                local u = (now / SHEEN_PERIOD) % 1
                sheen.Offset = Vector2.new(u * 2 - 1, 0)
                sheen.Rotation = 18 + 6 * math.sin(now * 1.1)
            end

            local titleGrad = titleGradRef.current
            if titleGrad then
                local u = (now / TITLE_SWEEP) % 1
                titleGrad.Offset = Vector2.new(u * 2 - 1, 0)
            end
        end)
        return function()
            conn:Disconnect()
        end
    end, {})

    return React.createElement("Frame", {
        Size = props.size or P.size,
        Position = props.position or P.pos,
        AnchorPoint = props.anchorPoint or P.anchor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ZIndex = 2,
    }, {
        -- Solid tint under transparent pack art.
        Fill = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            ZIndex = 0,
        }, {
            Gradient = React.createElement("UIGradient", {
                Color = tokens.specialPackSheen,
                Rotation = -12,
                ref = function(rbx: UIGradient?)
                    bgGradRef.current = rbx
                end,
            }),
            Stroke = React.createElement("UIStroke", {
                Color = tokens.titleShadow,
                Thickness = tokens.strokeCard,
                StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
            }),
        }),
        Bg = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = offer.image or "",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 1,
        }, {
            Gradient = React.createElement("UIGradient", {
                Color = tokens.specialPackSheen,
                Rotation = -12,
                ref = function(rbx: UIGradient?)
                    bgImageGradRef.current = rbx
                end,
            }),
        }),
        Sheen = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, {
            Gradient = React.createElement("UIGradient", {
                Color = tokens.specialPackSheen,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.35, 0.75),
                    NumberSequenceKeypoint.new(0.5, 0.35),
                    NumberSequenceKeypoint.new(0.65, 0.75),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation = 18,
                ref = function(rbx: UIGradient?)
                    sheenRef.current = rbx
                end,
            }),
        }),
        Icon1 = if icons[1]
            then React.createElement("ImageLabel", {
                Size = P.icon1.size,
                Position = P.icon1.pos,
                AnchorPoint = P.icon1.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = icons[1],
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 3,
            })
            else nil,
        Icon2 = if icons[2]
            then React.createElement("ImageLabel", {
                Size = P.icon2.size,
                Position = P.icon2.pos,
                AnchorPoint = P.icon2.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = icons[2],
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 3,
            })
            else nil,
        Icon3 = if icons[3]
            then React.createElement("ImageLabel", {
                Size = P.icon3.size,
                Position = P.icon3.pos,
                AnchorPoint = P.icon3.anchor,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = icons[3],
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 3,
            })
            else nil,
        Title = React.createElement(StrokeText, {
            text = offer.title,
            strokeThickness = tokens.strokeText,
            size = P.title.size,
            position = P.title.pos,
            anchorPoint = P.title.anchor,
            zIndex = 4,
            gradient = {
                color = tokens.specialPackTitle,
                rotation = 0,
            },
            gradientRef = function(rbx: UIGradient?)
                titleGradRef.current = rbx
            end,
        }),
        Desc = React.createElement(StrokeText, {
            text = offer.description or "",
            strokeThickness = tokens.strokeText,
            size = P.desc.size,
            position = P.desc.pos,
            anchorPoint = P.desc.anchor,
            zIndex = 4,
            color = Color3.fromRGB(255, 235, 200),
        }),
        Buy = React.createElement(RobuxButton, {
            price = offer.offer.price,
            originalPrice = offer.offer.originalPrice,
            variant = buyVariant,
            size = P.buy.size,
            position = P.buy.pos,
            anchorPoint = P.buy.anchor,
            onActivated = function()
                props.onBuy(offer.offer.productId)
            end,
        }),
        Gift = React.createElement(GiftButton, {
            size = P.gift.size,
            position = P.gift.pos,
            anchorPoint = P.gift.anchor,
            onActivated = if props.onGift
                then function()
                    props.onGift(offer.offer.productId)
                end
                else nil,
        }),
    })
end

return SpecialPackCard
