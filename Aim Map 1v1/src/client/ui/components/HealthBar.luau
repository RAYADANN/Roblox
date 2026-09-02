--!strict
-- HP bar fills parent (Scale layout). TextScaled — no fixed TextSize.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type Props = {
    health: number,
    maxHealth: number,
    layoutOrder: number?,
}

local function accentForRatio(ratio: number): Color3
    if ratio > 0.55 then
        return theme.Colors.success
    elseif ratio > 0.28 then
        return theme.Colors.gold
    end
    return theme.Colors.error
end

local function HealthBar(props: Props): React.Node
    local maxHp = math.max(1, props.maxHealth)
    local ratio = math.clamp(props.health / maxHp, 0, 1)
    local accent = accentForRatio(ratio)
    local hpText = `{math.ceil(props.health)} / {math.ceil(maxHp)}`

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        LayoutOrder = props.layoutOrder,
    }, {
        LabelRow = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 0.4),
            BackgroundTransparency = 1,
        }, {
            Title = React.createElement("TextLabel", {
                Size = UDim2.fromScale(0.35, 1),
                BackgroundTransparency = 1,
                Text = "HP",
                TextColor3 = theme.Colors.textSub,
                TextScaled = true,
                Font = theme.Font.body,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            Value = React.createElement("TextLabel", {
                Size = UDim2.fromScale(0.65, 1),
                Position = UDim2.fromScale(0.35, 0),
                BackgroundTransparency = 1,
                Text = hpText,
                TextColor3 = theme.Colors.textMain,
                TextScaled = true,
                Font = theme.Font.title,
                TextXAlignment = Enum.TextXAlignment.Right,
            }),
        }),
        Track = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 0.42),
            Position = UDim2.fromScale(0, 0.52),
            BackgroundColor3 = theme.Colors.bg1,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.35, 0) }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.dockBorder,
                Thickness = theme.Stroke.thin,
            }),
            Fill = React.createElement("Frame", {
                Size = UDim2.fromScale(ratio, 1),
                BackgroundColor3 = accent,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.35, 0) }),
            }),
        }),
    })
end

return HealthBar
