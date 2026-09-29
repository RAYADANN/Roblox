--!strict
-- Centered panel host (Aim Map pattern). Prefer Scale size on DesignRoot canvas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type Props = {
    size: UDim2,
    position: UDim2?,
    anchor: Vector2?,
    backgroundTransparency: number?,
    zIndex: number?,
    children: { [string]: React.Node }?,
}

local function DesignPanel(props: Props): React.Node
    return React.createElement("Frame", {
        Size = props.size,
        Position = props.position or UDim2.fromScale(0.5, 0.5),
        AnchorPoint = props.anchor or Vector2.new(0.5, 0.5),
        BackgroundTransparency = if props.backgroundTransparency ~= nil
            then props.backgroundTransparency
            else 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = props.zIndex,
    }, props.children)
end

return DesignPanel
