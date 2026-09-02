--!strict
-- Fixed 1920×1080 canvas + UIScale driven by viewport (inside React tree).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local UiScaler = require(script.Parent.adapt.UiScaler)

export type Props = {
    children: React.Node?,
    config: UiScaler.Config?,
}

local function DesignRoot(props: Props): React.Node
    local config = props.config
    local ref = UiScaler.getReference(config)
    local scale, setScale = React.useState(function()
        return UiScaler.compute(config)
    end)

    React.useEffect(function()
        return UiScaler.listen(config, setScale)
    end, {})

    local children: { [string]: React.Node } = {
        -- MUST live in React tree — createRoot would wipe an external UIScale
        Scaler = React.createElement("UIScale", {
            Scale = scale,
        }),
    }

    local incoming = props.children
    if typeof(incoming) == "table" then
        for key, node in incoming :: { [string]: React.Node } do
            children[key] = node
        end
    elseif incoming ~= nil then
        children.Child = incoming :: React.Node
    end

    return React.createElement("Frame", {
        Size = UDim2.fromOffset(ref.X, ref.Y),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, children)
end

return DesignRoot
