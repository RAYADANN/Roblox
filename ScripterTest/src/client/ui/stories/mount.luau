--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local DesignRoot = require(script.Parent.Parent.DesignRoot)

local function mount(element: React.Node): (Instance) -> () -> ()
	return function(target: Instance)
		local root = ReactRoblox.createRoot(target)
		root:render(React.createElement(DesignRoot, nil, {
			Content = element,
		}))
		return function()
			root:unmount()
		end
	end
end

return mount
