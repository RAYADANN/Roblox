--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local Hud = require(script.Parent.Parent.components.Hud)
local mount = require(script.Parent.mount)

return mount(React.createElement(DesignRoot, {
	config = {
		reference = Vector2.new(1920, 1080),
		minScale = 0.45,
		maxScale = 1.6,
		fit = true,
		mobileBoost = 2.25,
		mobileBelow = 900,
	},
}, {
	Hud = React.createElement(Hud, {
		onAction = function(icon)
			print("hud:", icon)
		end,
	}),
}))
