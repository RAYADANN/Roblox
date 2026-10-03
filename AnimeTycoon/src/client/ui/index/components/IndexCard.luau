--!strict
-- Index card = StarterGui NormalItem + mutation/rarity shine text + hero viewport.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IndexHeroViewport = require(script.Parent.IndexHeroViewport)
local IndexShineStrokeText = require(script.Parent.IndexShineStrokeText)
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
    local mutations: { string }? = if item.tier ~= "normal" then { item.tier } else nil
    local showHero = unlocked and typeof(item.heroId) == "string" and item.heroId ~= ""

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
        Hero = if showHero
            then React.createElement(IndexHeroViewport, {
                heroId = item.heroId :: string,
                rarity = item.rarity or "common",
                mutations = mutations,
                size = C.hero.size,
                position = C.hero.pos,
                anchorPoint = C.hero.anchor,
                zIndex = 2,
            })
            else nil,
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
        Mutation = React.createElement("Frame", {
            Size = C.mutation.size,
            Position = C.mutation.pos,
            AnchorPoint = C.mutation.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, {
            Text = if unlocked
                then React.createElement(IndexShineStrokeText, {
                    text = item.mutationText,
                    shineKind = "mutation",
                    shineKey = item.mutationText,
                    size = UDim2.fromScale(1, 1),
                    zIndex = 3,
                })
                else React.createElement(StrokeText, {
                    text = "???",
                    strokeThickness = tokens.strokeText,
                    size = UDim2.fromScale(1, 1),
                    zIndex = 3,
                }),
        }),
        Rare = React.createElement("Frame", {
            Size = C.rare.size,
            Position = C.rare.pos,
            AnchorPoint = C.rare.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, {
            Text = if unlocked
                then React.createElement(IndexShineStrokeText, {
                    text = item.rareText,
                    shineKind = "rarity",
                    shineKey = item.rareText,
                    size = UDim2.fromScale(1, 1),
                    zIndex = 3,
                })
                else React.createElement(StrokeText, {
                    text = "???",
                    strokeThickness = tokens.strokeText,
                    size = UDim2.fromScale(1, 1),
                    zIndex = 3,
                }),
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
