--!strict
-- Thin readiness bar under the crosshair (fills while USP cools down).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local FireCooldownState = require(script.Parent.Parent.Parent.core.FireCooldownState)
local theme = require(script.Parent.Parent.theme)

local function FireCooldownBar(): React.Node
    local progress, setProgress = React.useState(1)

    React.useEffect(function()
        local last = -1
        local conn = RunService.RenderStepped:Connect(function()
            local nextProgress = FireCooldownState.getProgress()
            if math.abs(nextProgress - last) < 0.02 and (nextProgress >= 1) == (last >= 1) then
                return
            end
            last = nextProgress
            setProgress(nextProgress)
        end)
        return function()
            conn:Disconnect()
        end
    end, {})

    local ready = progress >= 0.999

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(84, 6),
        Position = UDim2.new(0.5, 0, 0.5, 42),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = theme.Colors.bg1,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, {
        Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Stroke = React.createElement("UIStroke", {
            Color = theme.Colors.dockBorder,
            Thickness = 1,
            Transparency = 0.35,
        }),
        Fill = React.createElement("Frame", {
            Size = UDim2.fromScale(progress, 1),
            BackgroundColor3 = if ready then theme.Colors.sell else theme.Colors.gold,
            BorderSizePixel = 0,
            ZIndex = 6,
        }, {
            Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
        }),
    })
end

return FireCooldownBar
