--!strict
-- React toast list (replaces imperative Notification ScreenGui).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local Toast = require(script.Parent.Toast)
local useDesign = require(script.Parent.Parent.hooks.useDesign)

export type ToastItem = Toast.ToastItem

export type Props = {
    items: { ToastItem },
}

local function ToastStack(props: Props): React.Node
    local design = useDesign()
    local children: { [string]: React.Node } = {
        List = React.createElement("UIListLayout", {
            Padding = UDim.new(0, 9),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    }

    for i, item in props.items do
        children[`T{item.id}`] = React.createElement(Toast, {
            item = item,
            layoutOrder = i,
        })
    end

    return React.createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 300),
        Position = UDim2.new(0.5, 0, 0, design.safeTop + 12),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 20,
    }, children)
end

return ToastStack
