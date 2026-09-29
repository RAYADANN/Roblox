--!strict
-- Hoarcekat: Index window. Path: ReplicatedStorage.UI.stories.Index
-- sync: golden tab 89398273168867 v13

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IndexPanel = require(script.Parent.Parent.index.IndexPanel)
local mount = require(script.Parent.mount)
local types = require(script.Parent.Parent.index.types)

local function Story(): React.Node
    return React.createElement(IndexPanel, {
        onClose = function()
            print("[Index] close")
        end,
        onSelectTier = function(tier: types.IndexTier)
            print(`[Index] tier {tier}`)
        end,
    })
end

return mount.screen(React.createElement(Story))
