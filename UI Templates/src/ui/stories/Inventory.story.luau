--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local App = require(script.Parent.Parent.App)
local mount = require(script.Parent.mount)

return mount(React.createElement(App))
