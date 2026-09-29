--!strict
-- Hoarcekat: Cash packs. Path: ReplicatedStorage.UI.stories.Cash

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local CashPanel = require(script.Parent.Parent.shop.CashPanel)
local MockData = require(script.Parent.Parent.shop.MockData)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(CashPanel, {
        offers = MockData.cash(),
        onBuy = function(productId: string)
            print(`[Cash story] buy {productId}`)
        end,
        onGift = function(productId: string)
            print(`[Cash story] gift {productId}`)
        end,
        onClose = function()
            print("[Cash story] close")
        end,
    })
end

return mount.screen(React.createElement(Story))
