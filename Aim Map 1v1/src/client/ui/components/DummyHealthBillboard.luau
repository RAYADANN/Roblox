--!strict
-- World HP bar for practice bots (React → BillboardGui).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type Props = {
    name: string,
    health: number,
    maxHealth: number,
}

local function accentForRatio(ratio: number): Color3
    if ratio > 0.55 then
        return theme.Colors.success
    elseif ratio > 0.28 then
        return theme.Colors.gold
    end
    return theme.Colors.error
end

local function DummyHealthBillboard(props: Props): React.Node
    local maxHp = math.max(1, props.maxHealth)
    local ratio = math.clamp(props.health / maxHp, 0, 1)
    local accent = accentForRatio(ratio)

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, {
        NameLabel = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = props.name,
            TextColor3 = theme.Colors.gold,
            Font = theme.Font.title,
            TextSize = 12,
            TextStrokeTransparency = 0.5,
        }),
        Track = React.createElement("Frame", {
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.fromOffset(0, 16),
            BackgroundColor3 = theme.Colors.bg1,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 3) }),
            Fill = React.createElement("Frame", {
                Size = UDim2.new(ratio, 0, 1, 0),
                BackgroundColor3 = accent,
                BorderSizePixel = 0,
            }, {
                Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 3) }),
            }),
        }),
        HpText = React.createElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 12),
            Position = UDim2.fromOffset(0, 26),
            BackgroundTransparency = 1,
            Text = `{math.ceil(props.health)}`,
            TextColor3 = theme.Colors.textMain,
            Font = theme.Font.body,
            TextSize = 11,
            TextStrokeTransparency = 0.5,
        }),
    })
end

return DummyHealthBillboard
