--!strict
-- Stroked text in absolute pixels.
-- uniformFitRef: the box is absolute; the point size follows a reference string,
-- so a longer label does not shrink the title.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)
local useLayout = require(script.Parent.Parent.hooks.useLayout)

export type Props = {
    text: string,
    --- Design pixels. Ignored while uniformFitRef is set.
    textSize: number?,
    color: Color3?,
    --- Design pixels. FixedSize stroke, not ScaledSize.
    strokeThickness: number?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
    layoutOrder: number?,
    textXAlignment: Enum.TextXAlignment?,
    textYAlignment: Enum.TextYAlignment?,
    zIndex: number?,
    font: Enum.Font?,
    gradient: {
        color: ColorSequence,
        rotation: number?,
    }?,
    strokeColor: Color3?,
    --- Parent already has UIScale (window design space). Do not also call layout.text.
    designSpace: boolean?,
    --- Measure this string instead of `text`, so siblings share one point size.
    uniformFitRef: string?,
}

local MAX_TEXT_SIZE = 100

local function StrokeText(props: Props): React.Node
    local layout = useLayout()
    local font = props.font or theme.Font.title
    local zIndex = props.zIndex or 1
    local designStroke = props.strokeThickness or theme.Stroke.thick
    local strokeThickness = if props.designSpace then designStroke else layout.px(designStroke)
    local uniformRef = props.uniformFitRef

    local scaleB, setScale = React.useBinding(1)
    local lastKeyRef = React.useRef("")

    local function syncFit(host: GuiObject)
        local ax = host.AbsoluteSize.X
        local ay = host.AbsoluteSize.Y
        if ax < 2 or ay < 2 then
            return
        end
        local measureText = if uniformRef ~= nil and uniformRef ~= ""
            then uniformRef
            else props.text
        local bounds = TextService:GetTextSize(
            measureText,
            MAX_TEXT_SIZE,
            font,
            Vector2.new(100000, MAX_TEXT_SIZE * 2)
        )
        local sx = ax / math.max(1, bounds.X)
        local sy = ay / math.max(1, bounds.Y)
        local s = math.min(sx, sy)
        local key = string.format("%.3f:%s", s, measureText)
        if lastKeyRef.current == key then
            return
        end
        lastKeyRef.current = key
        setScale(s)
    end

    local stroke = React.createElement("UIStroke", {
        Color = props.strokeColor or theme.Colors.outlineDark,
        Thickness = strokeThickness,
        StrokeSizingMode = Enum.StrokeSizingMode.FixedSize,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        LineJoinMode = Enum.LineJoinMode.Bevel,
    })
    local gradient = if props.gradient
        then React.createElement("UIGradient", {
            Color = props.gradient.color,
            Rotation = props.gradient.rotation or 0,
        })
        else nil

    if uniformRef ~= nil then
        return React.createElement("Frame", {
            Size = props.size,
            Position = props.position,
            AnchorPoint = props.anchorPoint,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = props.layoutOrder,
            ZIndex = zIndex,
            ref = function(host: Frame?)
                if host ~= nil then
                    syncFit(host)
                end
            end,
            [React.Change.AbsoluteSize] = function(host: Frame)
                syncFit(host)
            end,
        }, {
            Label = React.createElement("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.XY,
                Size = UDim2.fromOffset(0, 0),
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = props.text,
                TextScaled = false,
                TextSize = MAX_TEXT_SIZE,
                Font = font,
                TextColor3 = props.color or theme.Colors.textMain,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = zIndex,
            }, {
                Scale = React.createElement("UIScale", { Scale = scaleB }),
                Stroke = stroke,
                Gradient = gradient,
            }),
        })
    end

    local designSize = props.textSize or 16
    local textSize = if props.designSpace then designSize else layout.text(designSize)

    return React.createElement("TextLabel", {
        Size = props.size,
        Position = props.position,
        AnchorPoint = props.anchorPoint,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = props.text,
        TextScaled = false,
        TextSize = textSize,
        Font = font,
        TextColor3 = props.color or theme.Colors.textMain,
        TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Center,
        TextYAlignment = props.textYAlignment or Enum.TextYAlignment.Center,
        LayoutOrder = props.layoutOrder,
        ZIndex = zIndex,
    }, {
        Stroke = stroke,
        Gradient = gradient,
    })
end

return StrokeText
