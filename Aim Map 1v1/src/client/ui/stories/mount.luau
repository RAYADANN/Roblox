--!strict
-- Hoarcekat mount — always DesignRoot + adapt.DEFAULT (one scale for the game).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local adapt = require(script.Parent.Parent.adapt)

local function mount(element: React.Node): (Instance) -> () -> ()
    return function(target: Instance)
        local root = ReactRoblox.createRoot(target)
        root:render(React.createElement(DesignRoot, {
            config = adapt.DEFAULT,
        }, {
            Content = element,
        }))
        return function()
            root:unmount()
        end
    end
end

return mount
