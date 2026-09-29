--!strict
-- Hoarcekat mounts. Screen-scale HUD (BalanceChip uses screen Scale like Tycoon FarmHud).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReactRoblox = require(ReplicatedStorage:WaitForChild("Packages").ReactRoblox)

local ViewportLayout = require(script.Parent.Parent.util.ViewportLayout)

local function mountScreen(element: any): (Instance) -> () -> ()
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
    mount = mountScreen,
}
