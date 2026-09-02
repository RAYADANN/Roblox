--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local theme = require(script.Parent.Parent.theme)

export type Props = {
    progress: number,
    height: number?,
    accent: Color3?,
}

local function ProgressBar(props: Props): React.Node
    local h = props.height or 15
    local p = math.clamp(props.progress, 0, 1)
    local accent = props.accent or theme.Colors.primary

    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, h),
        BackgroundColor3 = theme.Colors.bg3,
        BorderSizePixel = 0,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Fill = React.createElement("Frame", {
            Size = UDim2.new(p, 0, 1, 0),
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        }),
    })
end

return ProgressBar
