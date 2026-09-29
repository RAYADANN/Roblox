--!strict
-- Hoarcekat: coins BalanceChip only (Tycoon parity). Path: ReplicatedStorage.UI.stories.BalanceChip

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local BalanceChip = require(script.Parent.Parent.components.BalanceChip)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    return React.createElement("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, {
        Coins = React.createElement(BalanceChip, { coins = 1_234_567 }),
    })
end

return mount.screen(React.createElement(Story))
