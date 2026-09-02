--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ProgressBar = require(script.Parent.ProgressBar)
local theme = require(script.Parent.Parent.theme)

export type Props = {
    progress: number,
    visible: boolean,
}

local function LoadingScreen(props: Props): React.Node
    if not props.visible then
        return nil
    end

    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.bg1,
        BorderSizePixel = 0,
        ZIndex = 1000,
    }, {
        Title = React.createElement("TextLabel", {
            Size = UDim2.fromOffset(450, 72),
            Position = UDim2.fromScale(0.5, 0.45),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Text = "Loading...",
            TextSize = 36,
            Font = theme.Font.heavy,
            TextColor3 = theme.Colors.textMain,
        }),
        BarWrap = React.createElement("Frame", {
            Size = UDim2.fromOffset(450, 15),
            Position = UDim2.new(0.5, 0, 0.52, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
        }, {
            Bar = React.createElement(ProgressBar, {
                progress = props.progress,
                height = 12,
            }),
        }),
    })
end

return LoadingScreen
