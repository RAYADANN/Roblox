--!strict
-- SimPop inventory tab — tone background (no shine), white stroke when selected.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ImageIds = require(script.Parent.block.ImageIds)
local playUiClick = require(script.Parent.Parent.util.playUiClick)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type TabTone = "blue" | "purple"

export type Props = {
    label: string,
    tone: TabTone?,
    selected: boolean?,
    size: UDim2?,
    layoutOrder: number?,
    onActivated: (() -> ())?,
}

local function SimPopTab(props: Props): React.Node
    local selected = props.selected == true
    local tone: TabTone = props.tone or "blue"
    local chrome = ImageIds.Block[tone]
    local hoverScale, handlers = useHoverPress({
        hoverScale = 1.04,
        pressScale = 0.96,
    })

    return React.createElement("Frame", {
        -- Height must be non-zero: UIListLayout + Size.Y=0 collapses tabs under UIScale.
        Size = props.size or UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder or 0,
    }, {
        Aspect = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = 1,
            DominantAxis = Enum.DominantAxis.Width,
        }),
        Unit = React.createElement("ImageButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = chrome.background,
            ScaleType = Enum.ScaleType.Stretch,
            [React.Event.Activated] = playUiClick.wrapActivated(props.onActivated),
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Scale = React.createElement("UIScale", { Scale = hoverScale }),
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(theme.SimPop.cornerScale, 0),
            }),
            Stroke = React.createElement("UIStroke", {
                Color = if selected then theme.Colors.white else theme.Colors.black,
                Thickness = if selected then theme.Stroke.panel else theme.Stroke.slot,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
            Label = React.createElement("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = props.label,
                Font = theme.Font.display,
                TextScaled = true,
                TextColor3 = theme.Colors.white,
                ZIndex = 2,
            }, {
                Pad = React.createElement("UIPadding", {
                    PaddingTop = UDim.new(0.18, 0),
                    PaddingBottom = UDim.new(0.18, 0),
                    PaddingLeft = UDim.new(0.08, 0),
                    PaddingRight = UDim.new(0.08, 0),
                }),
                Outline = React.createElement("UIStroke", {
                    Color = theme.Colors.black,
                    Thickness = theme.Stroke.text,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                }),
            }),
        }),
    })
end

return SimPopTab
