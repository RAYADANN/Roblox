--!strict
-- Hoarcekat: Gamepasses. Path: ReplicatedStorage.UI.stories.Gamepasses

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local GamepassesPanel = require(script.Parent.Parent.shop.GamepassesPanel)
local MockData = require(script.Parent.Parent.shop.MockData)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(GamepassesPanel, {
        offers = MockData.gamepasses(),
        onBuy = function(productId: string)
            print(`[Gamepasses story] buy {productId}`)
        end,
        onClose = function()
            print("[Gamepasses story] close")
        end,
    })
end

return mount.screen(React.createElement(Story))
