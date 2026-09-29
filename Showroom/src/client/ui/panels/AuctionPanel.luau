--!strict
-- Post-auction decision: pet preview + max bid + Sell / Run again.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Button = require(script.Parent.Parent.components.Button)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type AuctionView = {
    phase: string,
    displayName: string,
    rarity: string,
    sizeLabel: string,
    mutationLabel: string,
    mutationCount: number,
    currentBid: number,
    maxBid: number,
    remainingSec: number,
    runsUsed: number,
    maxRuns: number,
    nextCommission: number,
    lastBuyer: string,
    bidsJson: string,
    colorR: number,
    colorG: number,
    colorB: number,
    scale: number,
}

export type Props = {
    auction: AuctionView,
    onSell: () -> (),
    onRerun: () -> (),
}

local RARITY_COLOR: { [string]: Color3 } = {
    common = Color3.fromRGB(180, 180, 190),
    uncommon = Color3.fromRGB(80, 200, 120),
    rare = Color3.fromRGB(80, 140, 255),
    epic = Color3.fromRGB(180, 90, 255),
    legendary = Color3.fromRGB(255, 180, 40),
}

local function formatCoins(n: number): string
    local v = math.floor(n + 0.5)
    local s = tostring(v)
    local out = ""
    local count = 0
    for i = #s, 1, -1 do
        if count > 0 and count % 3 == 0 then
            out = " " .. out
        end
        out = string.sub(s, i, i) .. out
        count += 1
    end
    return out
end

local function AuctionPanel(props: Props): React.Node
    local layout = useLayout()
    local auction = props.auction
    local rarityColor = RARITY_COLOR[auction.rarity] or theme.Colors.textMuted
    local canRerun = auction.runsUsed < auction.maxRuns
    local petColor = Color3.fromRGB(auction.colorR, auction.colorG, auction.colorB)
    local modelSize = layout.px(math.clamp(80 * auction.scale, 64, 128))

    local mutText = if auction.mutationCount > 0 and auction.mutationLabel ~= ""
        then auction.mutationLabel
        else "No mutations"

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, {
        Panel = React.createElement("Frame", {
            Size = UDim2.fromOffset(layout.px(380), layout.px(340)),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.Colors.panelBg,
            BorderSizePixel = 0,
            ZIndex = 21,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.gold,
                Thickness = theme.Stroke.thick,
                Transparency = 0.15,
            }),
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, -layout.px(24), 0, layout.px(36)),
                Position = UDim2.fromOffset(layout.px(12), layout.px(12)),
                BackgroundTransparency = 1,
                Font = theme.Font.title,
                TextSize = layout.text(20),
                TextColor3 = theme.Colors.textMain,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "AUCTION ENDED",
            }),
            Model = React.createElement("Frame", {
                Size = UDim2.fromOffset(modelSize, modelSize),
                Position = UDim2.new(0.5, -modelSize / 2, 0, layout.px(56)),
                BackgroundColor3 = petColor,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
                Stroke = React.createElement("UIStroke", {
                    Color = rarityColor,
                    Thickness = 2,
                }),
            }),
            Name = React.createElement("TextLabel", {
                Size = UDim2.new(1, -layout.px(24), 0, layout.px(28)),
                Position = UDim2.fromOffset(
                    layout.px(12),
                    layout.px(56) + modelSize + layout.px(8)
                ),
                BackgroundTransparency = 1,
                Font = theme.Font.title,
                TextSize = layout.text(18),
                TextColor3 = theme.Colors.textMain,
                Text = auction.displayName,
            }),
            Meta = React.createElement("TextLabel", {
                Size = UDim2.new(1, -layout.px(24), 0, layout.px(36)),
                Position = UDim2.fromOffset(
                    layout.px(12),
                    layout.px(56) + modelSize + layout.px(36)
                ),
                BackgroundTransparency = 1,
                Font = theme.Font.body,
                TextSize = layout.text(13),
                TextColor3 = theme.Colors.textSub,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Text = `{string.upper(auction.rarity)} · {auction.sizeLabel} · {mutText}`,
            }),
            Bid = React.createElement("TextLabel", {
                Size = UDim2.new(1, -layout.px(24), 0, layout.px(32)),
                Position = UDim2.fromOffset(layout.px(12), layout.px(230)),
                BackgroundTransparency = 1,
                Font = theme.Font.title,
                TextSize = layout.text(22),
                TextColor3 = theme.Colors.gold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = `Max bid: {formatCoins(auction.maxBid)} coins`,
            }),
            Runs = React.createElement("TextLabel", {
                Size = UDim2.new(1, -layout.px(24), 0, layout.px(20)),
                Position = UDim2.fromOffset(layout.px(12), layout.px(262)),
                BackgroundTransparency = 1,
                Font = theme.Font.body,
                TextSize = layout.text(12),
                TextColor3 = theme.Colors.textMuted,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = if canRerun
                    then `Runs {auction.runsUsed}/{auction.maxRuns}`
                    else `Max auctions reached`,
            }),
            Footer = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, layout.px(48)),
                Position = UDim2.new(0, 0, 1, -layout.px(56)),
                BackgroundTransparency = 1,
            }, {
                Layout = React.createElement("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    Padding = UDim.new(0, layout.px(12)),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }),
                Sell = React.createElement(Button, {
                    label = "SELL",
                    variant = "sell",
                    layoutOrder = 1,
                    onActivated = props.onSell,
                }),
                Rerun = React.createElement(Button, {
                    label = if auction.nextCommission > 0
                        then `AGAIN · {formatCoins(auction.nextCommission)}`
                        else "RUN AGAIN",
                    variant = "secondary",
                    layoutOrder = 2,
                    disabled = not canRerun,
                    onActivated = props.onRerun,
                }),
            }),
        }),
    })
end

return AuctionPanel
