--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type ToastItem = {
    id: string,
    text: string,
    color: Color3?,
}

export type Props = {
    item: ToastItem,
    layoutOrder: number?,
}

local function Toast(props: Props): React.Node
    local color = props.item.color or theme.Colors.textMain

    return React.createElement("Frame", {
        Size = UDim2.new(0, 540, 0, 66),
        BackgroundColor3 = theme.Colors.bg3,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.chip }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.dockBorder,
            Thickness = theme.Stroke.thin,
        }),
        Label = React.createElement("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = props.item.text,
            TextSize = 21,
            Font = theme.Font.body,
            TextColor3 = color,
        }),
    })
end

return Toast
