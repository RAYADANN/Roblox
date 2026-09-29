--!strict
-- React toast preview (Hoarcekat). Runtime toasts use client/core/Notification.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IconCatalog = require(ReplicatedStorage.shared.data.IconCatalog)
local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type ToastItem = {
    id: string,
    text: string,
    color: Color3?,
}

export type Props = {
    item: ToastItem,
}

local function Toast(props: Props): React.Node
    local layout = useLayout()
    local color = props.item.color or theme.Colors.padGreen
    local bg =
        IconCatalog.resolveImage(IconCatalog.NotificationBackground, "NotificationBackground")

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(layout.px(520), layout.px(72)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Background = React.createElement("ImageLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = bg,
            ScaleType = Enum.ScaleType.Stretch,
        }),
        Label = React.createElement("TextLabel", {
            Size = UDim2.new(1, -layout.px(28), 1, 0),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = props.item.text,
            TextSize = layout.text(22),
            Font = theme.Font.heavy,
            TextColor3 = color,
            TextStrokeColor3 = theme.Colors.black,
            TextStrokeTransparency = 0.35,
            TextWrapped = true,
            ZIndex = 2,
        }),
    })
end

return Toast
