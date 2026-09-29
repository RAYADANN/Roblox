--!strict
-- Chrome DailyRewards: Stage → Window (icon в header).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DailyRewardsHeader = require(script.Parent.components.DailyRewardsHeader)
local SG = require(script.Parent.layout)
local tokens = require(script.Parent.tokens)

export type Props = {
    title: string,
    onClose: () -> (),
    children: React.Node?,
}

local function DailyRewardsWindow(props: Props): React.Node
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
                    Header = React.createElement(DailyRewardsHeader, {
                        title = props.title,
                        onClose = props.onClose,
                    }),
                }),
                Content = React.createElement("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 2,
                }, props.children),
            }),
        }),
    })
end

return DailyRewardsWindow
