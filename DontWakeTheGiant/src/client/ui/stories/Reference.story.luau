--!strict
-- Hoarcekat: ReplicatedStorage.UI.stories.Reference

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local MockData = require(script.Parent.Parent.reference.MockData)
local ReferencePanel = require(script.Parent.Parent.reference.ReferencePanel)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(ReferencePanel, {
        open = true,
        title = MockData.title,
        body = MockData.body,
        onClose = function() end,
    })
end

return mount.screen(React.createElement(Story))
