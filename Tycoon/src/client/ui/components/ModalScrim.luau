--!strict
-- Full-bleed modal backdrop on ModalHost (outside DesignRoot letterbox).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

export type Props = {
    onActivated: (() -> ())?,
    zIndex: number?,
}

local function ModalScrim(props: Props): React.Node
    return React.createElement("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(90, 90, 94),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = props.zIndex or 1,
        [React.Event.Activated] = if props.onActivated
            then function()
                props.onActivated()
            end
            else nil,
    })
end

return ModalScrim
