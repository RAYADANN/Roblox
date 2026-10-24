--!strict
-- Ввод игрока (GDD 11.2): красться C / Left Ctrl / ButtonB, бросить предмет Q / ButtonY.
-- Сервер решает скорость; клиент только шлёт намерение.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local Zap = require(script.Parent.Parent.net.NetClient)

local InputController = {}

local sneaking = false

function InputController.isSneaking(): boolean
    return sneaking
end

function InputController.setSneak(enabled: boolean)
    sneaking = enabled
    Zap.SetSneak.Fire(enabled)
end

function InputController.toggleSneak()
    InputController.setSneak(not sneaking)
end

function InputController.drop()
    Zap.DropItem.Fire({ _pad = 0 })
end

function InputController.start()
    ContextActionService:BindAction("DWTG_Sneak", function(_, state)
        if state == Enum.UserInputState.Begin then
            InputController.toggleSneak()
        end
        return Enum.ContextActionResult.Sink
    end, false, Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)

    ContextActionService:BindAction("DWTG_Drop", function(_, state)
        if state == Enum.UserInputState.Begin then
            InputController.drop()
        end
        return Enum.ContextActionResult.Sink
    end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonY)

    -- Новый персонаж начинает обычным шагом (сервер сбрасывает так же).
    Players.LocalPlayer.CharacterAdded:Connect(function()
        sneaking = false
    end)
end

return InputController
