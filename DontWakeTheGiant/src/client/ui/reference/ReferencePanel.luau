--!strict
-- Wired window: blur/zoom while open. Copy stays out of the chrome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ReferenceWindow = require(script.Parent.ReferenceWindow)
local useModalFocus = require(script.Parent.Parent.hooks.useModalFocus)

export type Props = {
    open: boolean,
    title: string,
    body: string,
    onClose: () -> (),
}

local function ReferencePanel(props: Props): React.Node
    useModalFocus(props.open)
    if not props.open then
        return nil
    end
    return React.createElement(ReferenceWindow, {
        title = props.title,
        body = props.body,
        onClose = props.onClose,
    })
end

return ReferencePanel
