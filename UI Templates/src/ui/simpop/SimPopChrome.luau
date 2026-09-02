--!strict
-- Shared SimPop chrome: shadow + ImageButton + stroke + shine + optional label/content.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)
local useMountAppear = require(script.Parent.Parent.hooks.useMountAppear)

export type ScrollRef = { current: ScrollingFrame? }

export type Props = {
    size: UDim2,
    background: string,
    shine: string,
    aspectRatio: number,
    shineWidth: number,
    shineAspect: number,
    cornerRadius: number,
    strokeThickness: number,
    label: string?,
    children: { [string]: React.Node }?,
    disabled: boolean?,
    layoutOrder: number?,
    appearDelay: number?,
    shineIntervalSec: number?,
    scrollRef: ScrollRef?,
    scrollMarginPx: number?,
    onActivated: (() -> ())?,
}

local SHADOW_Y = theme.Space.xs

local function SimPopChrome(props: Props): React.Node
    local disabled = props.disabled == true

    local hostRef = React.useRef(nil :: GuiObject?)
    local fallbackScrollRef = React.useRef(nil :: ScrollingFrame?)
    local scrollRef = props.scrollRef or fallbackScrollRef

    local visible, bumpVisibility = shine.useScrollVisibility({
        scrollRef = scrollRef,
        hostRef = hostRef,
        marginPx = props.scrollMarginPx,
        enabled = props.scrollRef ~= nil,
    })

    local appearScale, appearTransparency = useMountAppear({
        delay = props.appearDelay or 0,
    })
    local hoverScale, handlers = useHoverPress({
        disabled = disabled,
        hoverScale = if props.children then 1.04 else 1.035,
        pressScale = if props.children then 0.97 else 0.96,
    })
    local scale = appearScale * hoverScale

    local shineRef = shine.useShineRef({
        enabled = not disabled and visible,
        intervalSec = props.shineIntervalSec or 2,
        positionY = 0.5,
        shineWidth = props.shineWidth,
    })

    local faceSize = UDim2.new(1, 0, 1, -SHADOW_Y)

    local unitChildren: { [string]: React.Node } = {
        Scale = React.createElement("UIScale", { Scale = scale }),
        Shadow = React.createElement("ImageLabel", {
            Size = faceSize,
            Position = UDim2.fromOffset(0, SHADOW_Y),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = props.background,
            ImageColor3 = theme.Colors.black,
            ImageTransparency = appearTransparency,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(props.cornerRadius, 0),
            }),
        }),
        Hit = React.createElement("ImageButton", {
            Size = faceSize,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = props.background,
            ImageTransparency = appearTransparency,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
            Active = not disabled,
            [React.Event.Activated] = if disabled then nil else props.onActivated,
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(props.cornerRadius, 0),
            }),
            Stroke = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = props.strokeThickness,
                Transparency = appearTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        }),
        ShineClip = React.createElement("Frame", {
            Size = faceSize,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = false,
            ZIndex = 2,
        }, {
            Shine = React.createElement("ImageLabel", {
                Size = UDim2.new(props.shineWidth, 0, 1.08, 0),
                Position = UDim2.new(shine.startX(props.shineWidth), 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = props.shine,
                ImageTransparency = if visible then appearTransparency else 1,
                ScaleType = Enum.ScaleType.Fit,
                ref = shineRef,
            }, {
                Aspect = React.createElement("UIAspectRatioConstraint", {
                    AspectRatio = props.shineAspect,
                    DominantAxis = Enum.DominantAxis.Height,
                }),
            }),
        }),
    }

    if props.label then
        unitChildren.Label = React.createElement("TextLabel", {
            Size = faceSize,
            BackgroundTransparency = 1,
            Text = props.label,
            Font = theme.Font.display,
            TextScaled = true,
            TextColor3 = theme.Colors.white,
            TextTransparency = appearTransparency,
            TextStrokeTransparency = 1,
            Active = false,
            ZIndex = 3,
        }, {
            TextSizeConstraint = React.createElement("UITextSizeConstraint", {
                MinTextSize = 10,
                MaxTextSize = 72,
            }),
            Outline = React.createElement("UIStroke", {
                Color = theme.Colors.black,
                Thickness = theme.Stroke.text,
                Transparency = appearTransparency,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            }),
        })
    end

    if props.children then
        local contentChildren: { [string]: React.Node } = {
            Pad = React.createElement("UIPadding", {
                PaddingTop = UDim.new(0.08, 0),
                PaddingBottom = UDim.new(0.08, 0),
                PaddingLeft = UDim.new(0.08, 0),
                PaddingRight = UDim.new(0.08, 0),
            }),
        }
        for key, child in props.children do
            contentChildren[key] = child
        end
        unitChildren.Content = React.createElement("Frame", {
            Size = faceSize,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 4,
        }, contentChildren)
    end

    return React.createElement("Frame", {
        Size = props.size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ref = function(inst: GuiObject?)
            hostRef.current = inst
            bumpVisibility()
        end,
    }, {
        Aspect = React.createElement("UIAspectRatioConstraint", {
            AspectRatio = props.aspectRatio,
            DominantAxis = Enum.DominantAxis.Width,
        }),
        Unit = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, unitChildren),
    })
end

return SimPopChrome
