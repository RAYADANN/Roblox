--!strict
-- Starter leftover — not used by Aim Map HUD. Kept as UI atom example shell.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type Props = {
    upgradeId: string,
    label: string,
}

local function UpgradeRow(props: Props): React.Node
    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, theme.Design.ROW_H),
        BackgroundColor3 = theme.Colors.bg3,
        BorderSizePixel = 0,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
        Title = React.createElement("TextLabel", {
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.fromOffset(18, 0),
            BackgroundTransparency = 1,
            Text = props.label,
            TextSize = 21,
            Font = theme.Font.body,
            TextColor3 = theme.Colors.textMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
        }),
    })
end

return UpgradeRow
