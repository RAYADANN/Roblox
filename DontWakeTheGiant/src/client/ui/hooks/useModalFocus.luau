--!strict
-- Sync React "window open" → Lighting blur + camera FOV.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage:WaitForChild("Packages").React)

local ModalFocus = require(script.Parent.Parent.modal.ModalFocus)

local function useModalFocus(open: boolean)
    React.useEffect(function()
        ModalFocus.setOpen(open)
    end, { open })

    React.useEffect(function()
        return function()
            ModalFocus.destroy()
        end
    end, {})
end

return useModalFocus
