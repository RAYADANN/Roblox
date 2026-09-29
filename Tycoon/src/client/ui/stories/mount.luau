--!strict
-- Hoarcekat mounts. Screen-scale HUD vs DesignRoot canvas stories.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local DesignRoot = require(script.Parent.Parent.DesignRoot)
local adapt = require(script.Parent.Parent.adapt)

local function mountScreen(element: React.Node): (Instance) -> () -> ()
    return function(target: Instance)
        local root = ReactRoblox.createRoot(target)
        root:render(element)
        return function()
            root:unmount()
        end
    end
end

local function mountCanvas(element: React.Node): (Instance) -> () -> ()
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

return {
    screen = mountScreen,
    canvas = mountCanvas,
    -- Default kept for older stories that expect DesignRoot.
    mount = mountCanvas,
}
