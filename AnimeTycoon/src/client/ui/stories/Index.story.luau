--!strict
-- Hoarcekat: Index window. Path: ReplicatedStorage.UI.stories.Index
-- sync: tab H-scroll + card mutation/rarity gradients v15

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local IndexMockData = require(script.Parent.Parent.index.MockData)
local IndexPanel = require(script.Parent.Parent.index.IndexPanel)
local mount = require(script.Parent.mount)
local types = require(script.Parent.Parent.index.types)

local function Story(): React.Node
    return React.createElement(IndexPanel, {
        items = IndexMockData.items({ unlockAll = true }),
        onClose = function()
            print("[Index] close")
        end,
        onSelectTier = function(tier: types.IndexTier)
            print(`[Index] tier {tier}`)
        end,
    })
end

return mount.screen(React.createElement(Story))
