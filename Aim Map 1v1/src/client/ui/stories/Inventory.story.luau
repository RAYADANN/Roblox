--!strict
-- Hoarcekat: Inventory panel (GUN / CASE + rarity blocks).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local InventoryPanel = require(script.Parent.Parent.components.InventoryPanel)
local mount = require(script.Parent.mount)

local function Story(): React.Node
    local tab, setTab = React.useState("gun" :: "gun" | "case")
    local equipped, setEquipped = React.useState("usp_slate")

    return React.createElement(InventoryPanel, {
        ownedSkinIds = { "usp_default", "usp_slate", "usp_crimson" },
        equippedSkinId = equipped,
        tab = tab,
        onTabChange = setTab,
        onEquipSkin = function(skinId: string)
            setEquipped(skinId)
            print(`[Inventory] equip {skinId}`)
        end,
        onClose = function()
            print("[Inventory] close")
        end,
    })
end

return mount(React.createElement(Story))
