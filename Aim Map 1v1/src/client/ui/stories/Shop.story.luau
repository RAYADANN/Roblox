--!strict
-- Hoarcekat: Shop panel (case offer mockup).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ShopPanel = require(script.Parent.Parent.components.ShopPanel)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement(ShopPanel, {
        onBuy = function(offerId: string, qty: number)
            print(`[Shop] buy {qty}x {offerId}`)
        end,
        onBuyProduct = function(productId: string)
            print(`[Shop] buy product {productId}`)
        end,
        onClose = function()
            print("[Shop] close")
        end,
    })
end

return mount(React.createElement(Story))
