--!strict
-- Hoarcekat: весь магазин в одном окне (размеры = StarterGui).
-- Path: ReplicatedStorage.UI.stories.ExclusiveShop
-- sync: window titles uniformFitRef Rewards v34

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ExclusiveShopPanel = require(script.Parent.Parent.shop.ExclusiveShopPanel)
local MockData = require(script.Parent.Parent.shop.MockData)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(ExclusiveShopPanel, {
        boosts = MockData.boosts(),
        cash = MockData.cash(),
        onBuy = function(productId: string)
            print(`[Shop] buy {productId}`)
        end,
        onGift = function(productId: string)
            print(`[Shop] gift {productId}`)
        end,
        onClose = function()
            print("[Shop] close")
        end,
    })
end

return mount.screen(React.createElement(Story))
