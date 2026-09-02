--!strict
-- Track + fill. Fill width animates with Flipper (progress 0–1).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Gradient = require(script.Parent.Parent.util.Gradient)
local theme = require(script.Parent.Parent.theme)
local useProgress = require(script.Parent.Parent.hooks.useProgress)

export type Props = {
    tone: theme.BarTone,
    size: UDim2,
    -- 0–1 fill amount (default 1)
    progress: number?,
    appearDelay: number?,
    layoutOrder: number?,
}

local function GradientBar(props: Props): React.Node
    local grad = theme.BarGradients[props.tone]
    local fill = useProgress({
        progress = if props.progress ~= nil then props.progress else 1,
        delay = props.appearDelay or 0.15,
        frequency = 5,
        dampingRatio = 0.9,
    })

    return React.createElement("Frame", {
        Size = props.size,
        BackgroundColor3 = theme.Colors.black,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder,
        ClipsDescendants = true,
    }, {
        Corner = React.createElement("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.black,
            Thickness = theme.Stroke.bar,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }),
        Fill = React.createElement("Frame", {
            Size = UDim2.fromScale(math.clamp(fill, 0, 1), 1),
            BackgroundColor3 = theme.Colors.white,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", {
                CornerRadius = UDim.new(1, 0),
            }),
            Gradient = Gradient.element(grad),
        }),
    })
end

return GradientBar
