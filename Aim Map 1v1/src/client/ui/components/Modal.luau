--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ModalChrome = require(script.Parent.ModalChrome)
local theme = require(script.Parent.Parent.theme)

export type Props = {
    visible: boolean,
    title: string,
    onClose: () -> (),
    children: React.Node?,
}

local function Modal(props: Props): React.Node
    if not props.visible then
        return nil
    end

    -- Whole HUD already scales via DesignRoot; modal uses design size as-is.
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.bg1,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 10,
    }, {
        Chrome = React.createElement(ModalChrome, {
            title = props.title,
            onClose = props.onClose,
            children = props.children,
        }),
    })
end

return Modal
