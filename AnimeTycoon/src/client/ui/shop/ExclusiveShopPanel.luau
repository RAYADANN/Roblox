--!strict
-- Магазин: CanvasSize в Offset от AbsoluteSize (без AbsoluteContentSize — иначе петля).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BoostCard = require(script.Parent.components.BoostCard)
local CashCard = require(script.Parent.components.CashCard)
local SG = require(script.Parent.layout)
local ShopWindow = require(script.Parent.ShopWindow)
local SpecialPackCard = require(script.Parent.components.SpecialPackCard)
local StrokeText = require(script.Parent.components.StrokeText)
local tokens = require(script.Parent.tokens)
local types = require(script.Parent.types)

export type Props = {
    boosts: { types.BoostOffer },
    cash: { types.CashOffer },
    gamepasses: { types.GamepassOffer }?,
    onBuy: (productId: string) -> (),
    onGift: ((productId: string) -> ())?,
    onClose: () -> (),
}

local SECTION_COUNT = 3

type ScrollMetrics = {
    blockH: number,
    gap: number,
    canvasY: number,
}

local function sectionBlock(
    order: number,
    title: string,
    blockHB: any,
    content: { [string]: React.Node },
    labelPos: UDim2?
): React.Node
    local labelFrac = SG.sectionLabel.height
        / (SG.sectionLabel.height + SG.sectionLabel.contentGap + SG.section.height)
    local bodyFrac = SG.section.height
        / (SG.sectionLabel.height + SG.sectionLabel.contentGap + SG.section.height)

    return React.createElement("Frame", {
        Size = blockHB:map(function(h: number): UDim2
            return UDim2.new(1, 0, 0, h)
        end),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = order,
    }, {
        List = React.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 0),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
        Heading = React.createElement("Frame", {
            Size = UDim2.fromScale(1, labelFrac),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            ZIndex = SG.sectionLabel.zIndex,
        }, {
            Label = React.createElement(StrokeText, {
                text = title,
                strokeThickness = tokens.strokeText,
                size = SG.sectionLabel.size,
                position = labelPos or SG.sectionLabel.pos,
                anchorPoint = Vector2.new(0.5, 0.5),
                zIndex = SG.sectionLabel.zIndex,
                font = tokens.sectionFont,
            }),
        }),
        Body = React.createElement("Frame", {
            Size = UDim2.fromScale(1, bodyFrac),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 2,
            ClipsDescendants = true,
        }, content),
    })
end

local function ExclusiveShopPanel(props: Props): React.Node
    local b1, b2 = props.boosts[1], props.boosts[2]
    local L = SG.luck
    local M = SG.money
    local P = SG.specialPack
    local gamepasses = props.gamepasses or {}
    local special = gamepasses[1]

    local metricsB, setMetrics = React.useBinding({
        blockH = 0,
        gap = 0,
        canvasY = 0,
    } :: ScrollMetrics)
    local lastKeyRef = React.useRef("")

    local function syncMetrics(scroll: ScrollingFrame)
        local ay = scroll.AbsoluteSize.Y
        if ay <= 1 then
            return
        end
        local blockH = ay
            * (SG.sectionLabel.height + SG.sectionLabel.contentGap + SG.section.height)
        local gap = ay * SG.section.gap
        local canvasY = SECTION_COUNT * blockH
            + (SECTION_COUNT - 1) * gap
            + ay * SG.section.bottomPad
        local key = string.format("%.1f:%.1f:%.1f", blockH, gap, canvasY)
        if lastKeyRef.current == key then
            return
        end
        lastKeyRef.current = key
        setMetrics({
            blockH = blockH,
            gap = gap,
            canvasY = canvasY,
        })
    end

    local blockHB = metricsB:map(function(m: ScrollMetrics): number
        return m.blockH
    end)

    local cashChildren: { [string]: React.Node } = {}
    for i, offer in props.cash do
        local x = M.rowX[i]
        if x ~= nil then
            cashChildren["C" .. i] = React.createElement(CashCard, {
                offer = offer,
                onBuy = props.onBuy,
                onGift = props.onGift,
                size = M.size,
                position = UDim2.fromScale(x, M.rowY),
                anchorPoint = M.anchor,
            })
        end
    end

    return React.createElement(ShopWindow, {
        title = "Exclusive Shop",
        onClose = props.onClose,
    }, {
        Scroll = React.createElement("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = tokens.titleWhite,
            CanvasSize = metricsB:map(function(m: ScrollMetrics): UDim2
                return UDim2.fromOffset(0, m.canvasY)
            end),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Always,
            ClipsDescendants = true,
            ref = function(scroll: ScrollingFrame?)
                if scroll ~= nil then
                    syncMetrics(scroll)
                end
            end,
            [React.Change.AbsoluteSize] = function(scroll: ScrollingFrame)
                syncMetrics(scroll)
            end,
        }, {
            List = React.createElement("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = metricsB:map(function(m: ScrollMetrics): UDim
                    return UDim.new(0, m.gap)
                end),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),

            GamePass = sectionBlock(1, "GamePass", blockHB, {
                Pack = if special
                    then React.createElement(SpecialPackCard, {
                        offer = special,
                        onBuy = props.onBuy,
                        onGift = props.onGift,
                        size = P.size,
                        position = P.pos,
                        anchorPoint = P.anchor,
                    })
                    else nil,
            }, SG.sectionLabel.cashPos),

            Boosts = sectionBlock(2, "Boosts", blockHB, {
                Yellow = if b1
                    then React.createElement(BoostCard, {
                        offer = b1,
                        onBuy = props.onBuy,
                        onGift = props.onGift,
                        size = L.size,
                        position = L.leftPos,
                        anchorPoint = L.anchor,
                    })
                    else nil,
                Pink = if b2
                    then React.createElement(BoostCard, {
                        offer = b2,
                        onBuy = props.onBuy,
                        onGift = props.onGift,
                        size = L.size,
                        position = L.rightPos,
                        anchorPoint = L.anchor,
                    })
                    else nil,
            }, SG.sectionLabel.cashPos),

            Cash = sectionBlock(3, "Cash", blockHB, cashChildren, SG.sectionLabel.cashPos),
        }),
    })
end

return ExclusiveShopPanel
