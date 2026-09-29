--!strict
-- Hoarcekat: Boosts 2x2. Path: ReplicatedStorage.UI.stories.Boosts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BoostsPanel = require(script.Parent.Parent.shop.BoostsPanel)
local MockData = require(script.Parent.Parent.shop.MockData)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(BoostsPanel, {
        offers = MockData.boosts(),
        onBuy = function(productId: string)
            print(`[Boosts story] buy {productId}`)
        end,
        onGift = function(productId: string)
            print(`[Boosts story] gift {productId}`)
        end,
        onClose = function()
            print("[Boosts story] close")
        end,
    })
end

return mount.screen(React.createElement(Story))
