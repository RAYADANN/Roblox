--!strict
-- UI atom: theme + design-space sizes + useHoverPress (DesignRoot scales).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local playUiClick = require(script.Parent.Parent.util.playUiClick)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    label: string,
    onActivated: () -> (),
    variant: "primary" | "secondary" | "sell"?,
    disabled: boolean?,
    layoutOrder: number?,
    zIndex: number?,
    --- Design-space width @ 1920×1080 (default 180).
    width: number?,
    --- Design-space height (default ROW_H, min TOUCH_MIN).
    height: number?,
}

local function Button(props: Props): React.Node
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

    local h = math.max(props.height or theme.Design.ROW_H, theme.Design.TOUCH_MIN)
    local w = props.width or 180

    return React.createElement("TextButton", {
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = faceColor,
        BackgroundTransparency = if disabled then 0.4 else 0,
        BorderSizePixel = 0,
        Text = props.label,
        TextSize = 21,
        Font = theme.Font.title,
        TextColor3 = if disabled then theme.Colors.textMuted else textColor,
        AutoButtonColor = false,
        Active = not disabled,
        LayoutOrder = props.layoutOrder,
        ZIndex = props.zIndex,
        [React.Event.Activated] = if disabled
            then nil
            else playUiClick.wrapActivated(props.onActivated),
        [React.Event.MouseEnter] = handlers.onMouseEnter,
        [React.Event.MouseLeave] = handlers.onMouseLeave,
        [React.Event.MouseButton1Down] = handlers.onMouseDown,
        [React.Event.MouseButton1Up] = handlers.onMouseUp,
    }, {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Corner = React.createElement("UICorner", { CornerRadius = theme.Radius.btn }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.outlineDark,
            Thickness = theme.Stroke.medium,
            Transparency = 0.5,
        }),
    })
end

return Button
