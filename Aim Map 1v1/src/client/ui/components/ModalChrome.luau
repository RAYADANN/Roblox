--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Button = require(script.Parent.Button)
local theme = require(script.Parent.Parent.theme)

export type Props = {
    title: string,
    accent: Color3?,
    onClose: () -> (),
    children: React.Node?,
}

local function ModalChrome(props: Props): React.Node
    local accent = props.accent or theme.Colors.primary
    local w = theme.Design.MODAL_W
    local h = theme.Design.MODAL_H
    local headerH = theme.Design.HEADER_H

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, {
        Shell = React.createElement("Frame", {
            Size = UDim2.fromOffset(w, h),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.Colors.panelBg,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.panel }),
            Stroke = React.createElement("UIStroke", {
                Color = accent,
                Thickness = theme.Stroke.thick,
                Transparency = 0.12,
            }),
            AccentBar = React.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 4),
                BackgroundColor3 = accent,
                BorderSizePixel = 0,
            }),
            Title = React.createElement("TextLabel", {
                Size = UDim2.new(1, -120, 0, headerH),
                Position = UDim2.fromOffset(24, 12),
                BackgroundTransparency = 1,
                Text = props.title,
                TextSize = 30,
                Font = theme.Font.title,
                TextColor3 = theme.Colors.textMain,
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
            Close = React.createElement("Frame", {
                Size = UDim2.fromOffset(72, 72),
                Position = UDim2.new(1, -84, 0, 12),
                BackgroundTransparency = 1,
            }, {
                Btn = React.createElement(Button, {
                    label = "X",
                    variant = "secondary",
                    width = 72,
                    height = 72,
                    onActivated = props.onClose,
                }),
            }),
            Content = React.createElement("Frame", {
                Size = UDim2.new(1, -36, 1, -(headerH + 24)),
                Position = UDim2.new(0, 18, 0, headerH),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, props.children),
        }),
    })
end

return ModalChrome
