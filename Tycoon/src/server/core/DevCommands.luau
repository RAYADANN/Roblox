--!strict
-- Studio-only команды для теста баланса.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Logger = require(ReplicatedStorage.shared.util.Logger)

export type Deps = {
    mutateCoins: (player: Player, delta: number) -> boolean,
    resetProfile: (player: Player) -> boolean,
    clearGamepasses: (player: Player) -> boolean,
    clearExclusiveHeart: (player: Player) -> boolean,
    clearExclusiveOffers: (player: Player) -> boolean,
}

local DevCommands = {}

function DevCommands.start(deps: Deps)
    if not RunService:IsStudio() then
        return
    end

    local function onCommand(text: string, player: Player)
        if text == "/coins" or string.sub(text, 1, 7) == "/coins " then
            local amount = 1000
            local parts = string.split(text, " ")
            if parts[2] then
                amount = tonumber(parts[2]) or amount
            end
            if deps.mutateCoins(player, amount) then
                Logger.info("DevCommands", `+{amount} coins → {player.Name}`)
            end
        elseif text == "/reset" then
            if deps.resetProfile(player) then
                Logger.info("DevCommands", `reset profile → {player.Name}`)
            end
        elseif text == "/cleargamepasses" or text == "/cleargp" then
            if deps.clearGamepasses(player) then
                Logger.info("DevCommands", `cleared gamepasses → {player.Name}`)
            end
        elseif text == "/clearheart" or text == "/clearheartskin" then
            if deps.clearExclusiveHeart(player) then
                Logger.info("DevCommands", `cleared Heart Skin → {player.Name}`)
            end
        elseif text == "/clearexclusive" or text == "/clearex" then
            if deps.clearExclusiveOffers(player) then
                Logger.info("DevCommands", `cleared exclusive offers → {player.Name}`)
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

        local resetCmd = Instance.new("TextChatCommand")
        resetCmd.Name = "DevReset"
        resetCmd.PrimaryAlias = "/reset"
        resetCmd.Triggered:Connect(function(textSource, _message)
            local player = game:GetService("Players"):GetPlayerByUserId(textSource.UserId)
            if player then
                onCommand("/reset", player)
            end
        end)
        resetCmd.Parent = TextChatService

        local clearGpCmd = Instance.new("TextChatCommand")
        clearGpCmd.Name = "DevClearGamepasses"
        clearGpCmd.PrimaryAlias = "/cleargamepasses"
        clearGpCmd.SecondaryAlias = "/cleargp"
        clearGpCmd.Triggered:Connect(function(textSource, _message)
            local player = game:GetService("Players"):GetPlayerByUserId(textSource.UserId)
            if player then
                onCommand("/cleargamepasses", player)
            end
        end)
        clearGpCmd.Parent = TextChatService

        local clearHeartCmd = Instance.new("TextChatCommand")
        clearHeartCmd.Name = "DevClearHeart"
        clearHeartCmd.PrimaryAlias = "/clearheart"
        clearHeartCmd.SecondaryAlias = "/clearheartskin"
        clearHeartCmd.Triggered:Connect(function(textSource, _message)
            local player = game:GetService("Players"):GetPlayerByUserId(textSource.UserId)
            if player then
                onCommand("/clearheart", player)
            end
        end)
        clearHeartCmd.Parent = TextChatService

        local clearExCmd = Instance.new("TextChatCommand")
        clearExCmd.Name = "DevClearExclusive"
        clearExCmd.PrimaryAlias = "/clearexclusive"
        clearExCmd.SecondaryAlias = "/clearex"
        clearExCmd.Triggered:Connect(function(textSource, _message)
            local player = game:GetService("Players"):GetPlayerByUserId(textSource.UserId)
            if player then
                onCommand("/clearexclusive", player)
            end
        end)
        clearExCmd.Parent = TextChatService
    else
        Logger.warn("DevCommands", "legacy chat — wire manually if needed")
    end
end

return DevCommands
