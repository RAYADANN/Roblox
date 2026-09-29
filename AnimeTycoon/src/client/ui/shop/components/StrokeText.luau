--!strict
-- Текст: FredokaOne + ScaledSize UIStroke.
-- oversizedFit: TextSize=100 + UIScale под бокс (длина строки влияет на кегль).
-- uniformFitRef: кегль как у эталона (адаптив по боксу), длина своей строки не жмёт.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local tokens = require(script.Parent.Parent.tokens)
local useLayout = require(script.Parent.Parent.Parent.hooks.useLayout)

export type Props = {
    text: string,
    textSize: number?,
    color: Color3?,
    strokeThickness: number?,
    size: UDim2?,
    position: UDim2?,
    anchorPoint: Vector2?,
    layoutOrder: number?,
    textXAlignment: Enum.TextXAlignment?,
    textYAlignment: Enum.TextYAlignment?,
    zIndex: number?,
    textScaled: boolean?,
    textWrapped: boolean?,
    automaticSize: Enum.AutomaticSize?,
    font: Enum.Font?,
    gradient: {
        color: ColorSequence,
        rotation: number?,
    }?,
    oversizedFit: boolean?,
    -- Эталон для min(sx,sy) по AbsoluteSize хоста (напр. "REWARDS" / "Rewards")
    uniformFitRef: string?,
}

local MAX_TEXT_SIZE = 100

local function StrokeText(props: Props): React.Node
    local layout = useLayout()
    local font = props.font or tokens.font
    local zIndex = props.zIndex or 1
    local strokeThickness = props.strokeThickness or tokens.strokeText
    local wrapped = if props.textWrapped ~= nil then props.textWrapped else true
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
        local key = string.format("%.3f:%s:%s", s, measureText, props.text)
        if lastKeyRef.current == key then
            return
        end
        lastKeyRef.current = key
        setScale(s)
    end

    local stroke = React.createElement("UIStroke", {
        Color = tokens.titleShadow,
        Thickness = strokeThickness,
        StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
    })
    local gradient = if props.gradient
        then React.createElement("UIGradient", {
            Color = props.gradient.color,
            Rotation = props.gradient.rotation or 0,
        })
        else nil

    if props.oversizedFit or uniformRef ~= nil then
        return React.createElement("Frame", {
            Size = props.size or UDim2.fromScale(1, 1),
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
                TextColor3 = props.color or tokens.titleWhite,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextWrapped = false,
                ZIndex = zIndex,
            }, {
                Scale = React.createElement("UIScale", { Scale = scaleB }),
                Stroke = stroke,
                Gradient = gradient,
            }),
        })
    end

    local useScaled = props.textScaled ~= false

    return React.createElement("TextLabel", {
        Size = props.size or UDim2.fromScale(1, 1),
        Position = props.position,
        AnchorPoint = props.anchorPoint,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = props.automaticSize,
        Text = props.text,
        TextScaled = useScaled,
        TextSize = if useScaled then 14 else layout.text(props.textSize or 16),
        Font = font,
        TextColor3 = props.color or tokens.titleWhite,
        TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Center,
        TextYAlignment = props.textYAlignment or Enum.TextYAlignment.Center,
        TextWrapped = wrapped,
        LayoutOrder = props.layoutOrder,
        ZIndex = zIndex,
    }, {
        Stroke = stroke,
        Gradient = gradient,
    })
end

return StrokeText
