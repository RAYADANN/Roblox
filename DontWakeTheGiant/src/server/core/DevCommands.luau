--!strict
-- Studio-only команды для теста: /coins N, /noise N.
-- Для MCP-плейтеста: атрибут DebugSetNoise на ReplicatedStorage.GiantState (ставится на сервере).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Logger = require(ReplicatedStorage.shared.util.Logger)

export type Deps = {
    mutateCoins: (player: Player, delta: number) -> boolean,
    setNoise: (value: number) -> (),
}

local DevCommands = {}

local function command(name: string, alias: string, handler: (player: Player, arg: number?) -> ())
    local cmd = Instance.new("TextChatCommand")
    cmd.Name = name
    cmd.PrimaryAlias = alias
    cmd.Triggered:Connect(function(textSource, message)
        local player = Players:GetPlayerByUserId(textSource.UserId)
        if player then
            handler(player, tonumber(string.split(message, " ")[2]))
        end
    end)
    cmd.Parent = TextChatService
end

function DevCommands.start(deps: Deps)
    if not RunService:IsStudio() then
        return
    end

    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        command("DevCoins", "/coins", function(player, amount)
            if deps.mutateCoins(player, amount or 1000) then
                Logger.info("DevCommands", `+{amount or 1000} coins → {player.Name}`)
            end
        end)
        command("DevNoise", "/noise", function(_, value)
            deps.setNoise(value or 0)
        end)
    else
        Logger.warn("DevCommands", "legacy chat — wire manually if needed")
    end

    local state = ReplicatedStorage:FindFirstChild("GiantState")
    if state then
        state:GetAttributeChangedSignal("DebugSetNoise"):Connect(function()
            local value = state:GetAttribute("DebugSetNoise")
            if typeof(value) == "number" then
                deps.setNoise(value)
            end
        end)
    end
end

return DevCommands
