--!strict
-- Эталон UI-атома: theme + useLayout + useHoverPress + MotionPresets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    label: string,
    onActivated: () -> (),
    variant: "primary" | "secondary" | "sell"?,
    disabled: boolean?,
    layoutOrder: number?,
}

local function Button(props: Props): React.Node
    local layout = useLayout()
    local variant = props.variant or "primary"
    local disabled = props.disabled == true

    local scale, handlers = useHoverPress({
        disabled = disabled,
    })

    local faceColor = if variant == "sell"
        then theme.Colors.sell
        elseif variant == "secondary" then theme.Colors.bg3
        else theme.Colors.primary

    local textColor = if variant == "sell" or variant == "primary"
        then theme.Colors.white
        else theme.Colors.textMain

    local h = layout.touch(theme.Design.ROW_H)

    return React.createElement("TextButton", {
        Name = "Button",
        Size = UDim2.fromOffset(layout.px(120), h),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder,
        [React.Event.Activated] = if disabled then nil else props.onActivated,
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Face = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = faceColor,
            BackgroundTransparency = if disabled then 0.4 else 0,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.outlineDark,
                Thickness = theme.Stroke.medium,
                Transparency = 0.5,
            }),
            Label = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = props.label,
                TextSize = layout.text(14),
                Font = theme.Font.title,
                TextColor3 = if disabled then theme.Colors.textMuted else textColor,
            }),
        }),
    })
end

return Button
