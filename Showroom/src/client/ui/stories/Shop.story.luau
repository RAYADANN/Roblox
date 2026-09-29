--!strict
-- Hoarcekat: Shop modal (banners + coin packs).
-- Path: ReplicatedStorage.UI.stories.Shop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local ShopPanel = require(script.Parent.Parent.components.ShopPanel)
local mount = require(script.Parent.mount)
local theme = require(script.Parent.Parent.theme)

local function Story(): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Colors.bg2,
        BorderSizePixel = 0,
    }, {
        Canvas = React.createElement(DesignRoot, {}, {
            Panel = React.createElement(ShopPanel, {
                progress = {
                    coins = 12500,
                    incomePerSec = 80,
                },
                onBuyProduct = function(productId: string)
                    print(`[Shop story] buy {productId}`)
                end,
                onClose = function()
                    print("[Shop story] close")
                end,
            }),
        }),
    })
end

return mount.screen(React.createElement(Story))
