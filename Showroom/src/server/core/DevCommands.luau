--!strict
-- Studio-only команды для теста баланса.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Logger = require(ReplicatedStorage.shared.util.Logger)

export type Deps = {
    mutateCoins: (player: Player, delta: number) -> boolean,
}

local DevCommands = {}

function DevCommands.start(deps: Deps)
    if not RunService:IsStudio() then
        return
    end

    local function onCommand(text: string, player: Player)
        if text == "/coins" or text == "/coins 1000" then
            local amount = 1000
            local parts = string.split(text, " ")
            if parts[2] then
                amount = tonumber(parts[2]) or amount
            end
            if deps.mutateCoins(player, amount) then
                Logger.info("DevCommands", `+{amount} coins → {player.Name}`)
            end
        end
    end

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local cmd = Instance.new("TextChatCommand")
        cmd.Name = "DevCoins"
        cmd.PrimaryAlias = "/coins"
        cmd.SecondaryAlias = "/givecoins"
        cmd.Triggered:Connect(function(textSource, message)
            local player = game:GetService("Players"):GetPlayerByUserId(textSource.UserId)
            if player then
                onCommand(message, player)
            end
        end)
        cmd.Parent = TextChatService
    else
        Logger.warn("DevCommands", "legacy chat — wire manually if needed")
    end
end

return DevCommands
