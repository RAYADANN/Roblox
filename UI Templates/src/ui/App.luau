--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignRoot = require(script.Parent.DesignRoot)
local Hud = require(script.Parent.components.Hud)
local InventoryWindow = require(script.Parent.components.InventoryWindow)
local ImageIds = require(script.Parent.ImageIds)

local function App(): React.Node
	local inventoryOpen, setInventoryOpen = React.useState(false)

	local function onHudAction(icon: ImageIds.HudIcon)
		if icon == "inventory" then
			setInventoryOpen(true)
			return
		end
		print("hud:", icon)
	end

	local children: { [string]: React.Node } = {
		Hud = React.createElement(Hud, {
			onAction = onHudAction,
		}),
	}

	if inventoryOpen then
		children.Inventory = React.createElement(InventoryWindow, {
			onClose = function()
				setInventoryOpen(false)
			end,
		})
	end

	return React.createElement(DesignRoot, {
		config = {
			reference = Vector2.new(1920, 1080),
			minScale = 0.45,
			maxScale = 1.6,
			fit = true,
			mobileBoost = 2.25,
			mobileBelow = 900,
		},
	}, children)
end

return App
