--!strict
-- SimPop chrome (UI Templates tree):
--   Root → Unit → Shadow (ImageLabel) + Hit (ImageButton = face) + Shine/Label/Content
-- Shadow and Hit are the same size; Hit.Image fills Hit exactly. No bleed outside the frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local playUiClick = require(script.Parent.Parent.util.playUiClick)
local shine = require(script.Parent.Parent.shine)
local theme = require(script.Parent.Parent.theme)
local useHoverPress = require(script.Parent.Parent.hooks.useHoverPress)

export type Props = {
    size: UDim2,
    background: string,
    shine: string,
    --- nil = fill `size` (grid cells). number = lock aspect.
    aspectRatio: number?,
    shineWidth: number,
    --- nil = no aspect lock (long plates: fill height, width from shineWidth).
    shineAspect: number?,
    cornerScale: number?,
    strokeThickness: number?,
    strokeColor: Color3?,
    shadowColor: Color3?,
    --- Tint face chrome (frame-only tiles).
    imageColor: Color3?,
    label: string?,
    children: { [string]: React.Node }?,
    disabled: boolean?,
    layoutOrder: number?,
    shineIntervalSec: number?,
    onActivated: (() -> ())?,
}

local SHADOW_Y = theme.Space.xs

local function SimPopChrome(props: Props): React.Node
    local disabled = props.disabled == true
    local cornerScale = props.cornerScale or theme.SimPop.cornerScale
    local strokeThickness = props.strokeThickness or theme.Stroke.simPop
    local strokeColor = props.strokeColor or theme.Colors.black
    local shadowColor = props.shadowColor or theme.Colors.black
    local imageColor = props.imageColor or Color3.fromRGB(255, 255, 255)
    local hasChildren = props.children ~= nil

    local hoverScale, handlers = useHoverPress({
        disabled = disabled,
        hoverScale = if hasChildren then 1.04 else 1.035,
        pressScale = if hasChildren then 0.97 else 0.96,
    })

    local shineRef = shine.useShineRef({
        enabled = not disabled,
        intervalSec = props.shineIntervalSec or 2,
        positionY = 0.5,
        shineWidth = props.shineWidth,
    })

    local faceSize = UDim2.new(1, 0, 1, -SHADOW_Y)

    local unitChildren: { [string]: React.Node } = {
        Scale = React.createElement("UIScale", { Scale = hoverScale }),
        -- Same size as Hit; offset down. Tinted copy of the face image.
        Shadow = React.createElement("ImageLabel", {
            Size = faceSize,
            Position = UDim2.fromOffset(0, SHADOW_Y),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Image = props.background,
            ImageColor3 = shadowColor,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(cornerScale, 0),
            }),
        }),
        -- Main face: image IS the button, fills the frame 1:1.
        Hit = React.createElement("ImageButton", {
            Size = faceSize,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Image = props.background,
            ImageColor3 = imageColor,
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 1,
            Active = not disabled,
            [React.Event.Activated] = if disabled or props.onActivated == nil
                then nil
                else playUiClick.wrapActivated(props.onActivated),
            [React.Event.MouseEnter] = handlers.onMouseEnter,
            [React.Event.MouseLeave] = handlers.onMouseLeave,
            [React.Event.MouseButton1Down] = handlers.onMouseDown,
            [React.Event.MouseButton1Up] = handlers.onMouseUp,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(cornerScale, 0),
            }),
            Stroke = React.createElement("UIStroke", {
                Color = strokeColor,
                Thickness = strokeThickness,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        }),
        ShineClip = React.createElement("Frame", {
            Size = faceSize,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = false,
            -- Above Content so the sweep runs across the whole plate, not only empty gaps.
            ZIndex = 5,
        }, {
            Shine = React.createElement("ImageLabel", {
                Size = UDim2.new(props.shineWidth, 0, 1.08, 0),
                Position = UDim2.new(shine.startX(props.shineWidth), 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = props.shine,
                ScaleType = if props.shineAspect ~= nil
                    then Enum.ScaleType.Fit
                    else Enum.ScaleType.Stretch,
                ref = shineRef,
            }, {
                Aspect = if props.shineAspect ~= nil
                    then React.createElement("UIAspectRatioConstraint", {
                        AspectRatio = props.shineAspect :: number,
                        DominantAxis = Enum.DominantAxis.Height,
                    })
                    else nil,
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
    }, {
        Aspect = if props.aspectRatio ~= nil
            then React.createElement("UIAspectRatioConstraint", {
                AspectRatio = props.aspectRatio :: number,
                DominantAxis = Enum.DominantAxis.Width,
            })
            else nil,
        Unit = React.createElement("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, unitChildren),
    })
end

return SimPopChrome
