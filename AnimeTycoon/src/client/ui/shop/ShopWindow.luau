--!strict
-- Хром = StarterGui Stage → Window → Title (icon внутри header).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local SG = require(script.Parent.layout)
local ShopHeader = require(script.Parent.components.ShopHeader)
local tokens = require(script.Parent.tokens)

export type Props = {
    title: string,
    onClose: () -> (),
    children: React.Node?,
}

local function ShopWindow(props: Props): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = tokens.windowBg,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
    }, {
        Stage = React.createElement("Frame", {
            Size = SG.stage.size,
            Position = SG.stage.pos,
            AnchorPoint = SG.stage.anchor,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Window = React.createElement("Frame", {
                Size = SG.window.size,
                Position = SG.window.pos,
                AnchorPoint = SG.window.anchor,
                BackgroundColor3 = tokens.windowBg,
                BackgroundTransparency = tokens.windowBgTransparency,
                BorderSizePixel = 0,
                -- false: иконка в header может чуть выходить за верх Window
                ClipsDescendants = false,
                ZIndex = 1,
            }, {
                Aspect = React.createElement("UIAspectRatioConstraint", {
                    AspectRatio = SG.window.aspect,
                    AspectType = Enum.AspectType.FitWithinMaxSize,
                    DominantAxis = Enum.DominantAxis.Width,
                }),
                Stroke = React.createElement("UIStroke", {
                    Color = tokens.titleShadow,
                    Thickness = tokens.strokePanel,
                    StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
                }),
                Title = React.createElement("Frame", {
                    Size = SG.title.size,
                    Position = SG.title.pos,
                    AnchorPoint = SG.title.anchor,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = false,
                    ZIndex = 20,
                }, {
                    Header = React.createElement(ShopHeader, {
                        title = props.title,
                        onClose = props.onClose,
                    }),
                }),
                Body = React.createElement("Frame", {
                    Size = UDim2.new(1, 0, 1 - SG.content.top - SG.content.bottom, 0),
                    Position = UDim2.fromScale(0.5, SG.content.top),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 2,
                }, props.children),
            }),
        }),
    })
end

return ShopWindow
