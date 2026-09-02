--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ComponentGallery = require(script.Parent.Parent.ComponentGallery)
local mount = require(script.Parent.mount)

return mount(React.createElement(ComponentGallery))
