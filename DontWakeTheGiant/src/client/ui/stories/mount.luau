--!strict
-- Hoarcekat mount. Path: ReplicatedStorage.UI.stories

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local ViewportLayout = require(script.Parent.Parent.util.ViewportLayout)

local function mountScreen(element: React.Node): (Instance) -> () -> ()
    return function(target: Instance)
        ViewportLayout.start()
        local root = ReactRoblox.createRoot(target)
        root:render(element)
        return function()
            root:unmount()
        end
    end
end

return {
    screen = mountScreen,
}
